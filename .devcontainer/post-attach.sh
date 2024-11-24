#!/usr/bin/env bash

##########################
# Read some variables
read -p 'Operator token: ' OPERATOR_TOKEN
read -p 'Data ingest token: ' DATA_INGEST_TOKEN 
read -p 'Tenant ID: ' TENANT_ID

##########################
# Install Dynatrace
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/v1.3.2/kubernetes.yaml

[[ -z "$OPERATOR_TOKEN" ]] && echo "Variable Operator token not defined"
[[ -z "$DATA_INGEST_TOKEN" ]] && echo "Variable Date ingest token not defined"

kubectl -n dynatrace create secret generic dynakube --from-literal="apiToken=$OPERATOR_TOKEN" --from-literal="dataIngestToken=$DATA_INGEST_TOKEN"

sed -i 's/REPLACE_TENANT_ID/$TENANT_ID/g' dynatrace/application.yaml

sleep 20
kubectl apply -f dynatrace/application.yaml
sleep 30

##########################
# Install Easytrade
# create easytrade the namespace
kubectl create namespace easytrade

# then use the manifests to deploy
kubectl -n easytrade apply -f easytrade-k8s-manifests
# enable istio on the namespace
kubectl label namespace easytrade istio-injection=enabled
sleep 60

kubectl apply -f istio/istio-easytrade.yaml