#!/usr/bin/env bash

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
# Install Dynatrace
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/v1.3.2/kubernetes.yaml

read -p 'Operator Token:' OPERATOR_TOKEN
read -p 'Data ingest Token:' DATA_INGEST_TOKEN
read -p 'Tenant ID:' TENANT_ID

kubectl -n dynatrace create secret generic dynakube --from-literal="apiToken=$OPERATOR_TOKEN" --from-literal="dataIngestToken=$DATA_INGEST_TOKEN"
sed -i 's/REPLACE_TENANT_ID/$TENANT_ID/g' dynatrace/application.yaml

sleep 20
kubectl apply -f dynatrace/application.yaml
sleep 30

##########################
# create easytrade the namespace
kubectl create namespace easytrade

# then use the manifests to deploy
kubectl -n easytrade apply -f easytrade-k8s-manifests
# enable istio on the namespace
kubectl label namespace easytrade istio-injection=enabled
sleep 60

kubectl apply -f istio/istio-easytrade.yaml