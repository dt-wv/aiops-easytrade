#!/usr/bin/env bash

##########################
# Deploy Kind - k8s
kind create cluster --config .devcontainer/kind-cluster.yml --wait 300s
kubectl taint node kind-control-plane node-role.kubernetes.io/control-plane:NoSchedule-
kubectl label nodes kind-worker easytrade=true

########################## 
# istio setup
export PATH=$PWD/istio-1.24.0/bin:$PATH
chmod +x istio-1.24.0/bin/istioctl
istioctl install -f istio/istio-operator.yaml --skip-confirmation

sleep 30 

##########################
# update istio ingress
kubectl patch svc -n istio-system istio-ingressgateway --patch "$(cat istio/patch.yaml)"
kubectl delete pod --all -n istio-system

##########################
# Read some variables
clear
echo '###############################################'
echo '#          Dynatrace information              #'
echo '###############################################'
read -p 'Operator token: ' OPERATOR_TOKEN
read -p 'Data ingest token: ' DATA_INGEST_TOKEN 
read -p 'Tenant ID: ' TENANT_ID

##########################
# Install Dynatrace
kubectl create namespace dynatrace
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/v1.3.2/kubernetes.yaml
kubectl -n dynatrace wait pod --for=condition=ready --selector=app.kubernetes.io/name=dynatrace-operator,app.kubernetes.io/component=webhook --timeout=120s
kubectl -n dynatrace create secret generic dynakube --from-literal="apiToken=$OPERATOR_TOKEN" --from-literal="dataIngestToken=$DATA_INGEST_TOKEN"

sed -i "s/REPLACE_TENANT_ID/$TENANT_ID/g" dynatrace/application.yaml

kubectl apply -f dynatrace/application.yaml
sleep 60

##########################
# Install Easytrade
# create easytrade namespace and label and istio injection
kubectl create namespace easytrade
kubectl label namespace easytrade istio-injection=enabled

# then use the manifests to deploy
kubectl -n easytrade apply -f easytrade-k8s-manifests

sleep 120

kubectl apply -f istio/istio-easytrade.yaml

sleep 30
## label for oneagent injection and inject per deployment
kubectl label namespace easytrade instrumentation=oneagent
for i in $(kubectl get pods -n easytrade | awk '{print $1}'); do kubectl rollout restart -n easytrade deployment $1; sleep 80 ;done