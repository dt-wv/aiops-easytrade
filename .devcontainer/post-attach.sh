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
read -p 'Log ingest token: ' LOG_TOKEN 
read -p 'Terraform token: ' DYNATRACE_API_TOKEN
read -p 'Tenant ID: ' TENANT_ID

#### Some vars
DYNATRACE_ENV_URL="$TENANT_ID.live.dynatrace.com"
suffix=`cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1`
date_suffix=`date +"%Y-%m-%d-%s"`

##########################
# Install Dynatrace
kubectl create namespace dynatrace
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/v1.3.2/kubernetes.yaml
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/v1.3.2/kubernetes-csi.yaml
kubectl -n dynatrace wait pod --for=condition=ready --selector=app.kubernetes.io/name=dynatrace-operator,app.kubernetes.io/component=webhook --timeout=120s
kubectl -n dynatrace create secret generic dynakube --from-literal="apiToken=$OPERATOR_TOKEN" --from-literal="dataIngestToken=$DATA_INGEST_TOKEN"

sed -i "s/REPLACE_NAME/$suffix/g" dynatrace/application.yaml
sed -i "s/REPLACE_TENANT_ID/$TENANT_ID/g" dynatrace/application.yaml
sed -i "s/REPLACE_TENANT_ID/$TENANT_ID/g" dynatrace/fluent-bit-values.yaml
sed -i "s/REPLACE_LOG_TOKEN/$LOG_TOKEN/g" dynatrace/fluent-bit-values.yaml
sed -i "s/REPLACE_DATE/$date_suffix/g" dynatrace/fluent-bit-values.yaml

kubectl apply -f dynatrace/application.yaml
sleep 60

##########################
# Install Easytrade
# create easytrade namespace and label and istio injection
kubectl create namespace easytrade

# then use the manifests to deploy
kubectl -n easytrade apply -f easytrade-k8s-manifests

sleep 120

kubectl apply -f istio/istio-easytrade.yaml

sleep 30
##########################
# Install Fluent-bit
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update
helm install fluent-bit fluent/fluent-bit -f dynatrace/fluent-bit-values.yaml \
--create-namespace \
--namespace dynatrace-fluent-bit

## label for oneagent injection and inject per deployment
kubectl label namespace easytrade instrumentation=oneagent
for i in $(kubectl get deployments -n easytrade -o=jsonpath='{.items[*].metadata.name}'); do kubectl rollout restart -n easytrade deployment $i ; sleep 60 ; done

echo ""
echo "[+] Demo installation completed"
echo ""
echo "Kubernetes Dynatrace cluster: k8s-kind-easytrade-$suffix"
echo ""