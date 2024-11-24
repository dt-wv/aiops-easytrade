#!/usr/bin/env bash

##########################
# Deploy Kind - k8s
kind create cluster --config .devcontainer/kind-cluster.yml --wait 300s

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

kubectl -n dynatrace create secret generic dynakube --from-literal="apiToken=$OPERATOR_TOKEN" --from-literal="dataIngestToken=$DATA_INGEST_TOKEN"

sed -i 's/REPLACE_TENANT_ID/$TENANT_ID/g' dynatrace/application.yaml

sleep 20
kubectl apply -f dynatrace/application.yaml
sleep 30

##########################
# Install Easytrade
# create easytrade namespace and label for oneagent and istio injection
kubectl create namespace easytrade
kubectl label namespace easytrade instrumentation=oneagent
kubectl label namespace easytrade istio-injection=enabled

# then use the manifests to deploy
kubectl -n easytrade apply -f easytrade-k8s-manifests

sleep 60

kubectl apply -f istio/istio-easytrade.yaml