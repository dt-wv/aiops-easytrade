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

if [ -z "$OPERATOR_TOKEN" ]; then
  read -p 'Operator token: ' OPERATOR_TOKEN
else
  echo "OPERATOR_TOKEN has been set"
fi

if [ -z "$DATA_INGEST_TOKEN" ]; then
  read -p 'Data ingest token: ' DATA_INGEST_TOKEN
else
  echo "DATA_INGEST_TOKEN has been set"
fi

if [ -z "$LOG_TOKEN" ]; then
  read -p 'Log ingest token: ' LOG_TOKEN
else
  echo "LOG_TOKEN has been set"
fi

if [ -z "$BIZEVENT_TOKEN" ]; then
  read -p 'BizEvent ingest token: ' BIZEVENT_TOKEN
else
  echo "BIZEVENT_TOKEN has been set"
fi

if [ -z "$DYNATRACE_API_TOKEN" ]; then
  read -p 'Terraform token: ' DYNATRACE_API_TOKEN
else
  echo "DYNATRACE_API_TOKEN has been set"
fi

if [ -z "$DT_CLIENT_ID" ]; then
  read -p 'Terraform oauth client id: ' DT_CLIENT_ID
else
  echo "DT_CLIENT_ID has been set"
fi

if [ -z "$DT_CLIENT_SECRET" ]; then
  read -p 'Terraform client secret: ' DT_CLIENT_SECRET
else
  echo "DT_CLIENT_SECRET has been set"
fi

if [ -z "$DT_ACCOUNT_ID" ]; then
  read -p 'Terraform account id (urn): ' DT_ACCOUNT_ID
else
  echo "DT_ACCOUNT_ID has been set"
fi

if [ -z "$TENANT_ID" ]; then
  read -p 'Tenant ID: ' TENANT_ID
else
  echo "TENANT_ID has been set"
fi


#### Some vars
export DYNATRACE_ENV_URL="https://$TENANT_ID.live.dynatrace.com"
export DYNATRACE_API_TOKEN
export DT_CLIENT_ID
export DT_CLIENT_SECRET
export DT_ACCOUNT_ID
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
sed -i "s/REPLACE_SERVICE_URL/$CODESPACE_NAME/g" workflow/wftpl_aiops-easytrade-demo.yaml
sed -i "s/REPLACE_TENANT_ID/$TENANT_ID/g" workflow/wftpl_aiops-easytrade-demo.yaml
sed -i "s/REPLACE_BIZEVENT_TOKEN/$BIZEVENT_TOKEN/g" workflow/wftpl_aiops-easytrade-demo.yaml

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

##########################
# Configuration via Terraform
cd terraform && terraform init && terraform plan && terraform apply --auto-approve

## label for oneagent injection and inject per deployment
kubectl label namespace easytrade instrumentation=oneagent
for i in $(kubectl get deployments -n easytrade -o=jsonpath='{.items[*].metadata.name}'); do kubectl rollout restart -n easytrade deployment $i ; sleep 60 ; done

echo ""
echo "[+] Demo installation completed"
echo ""
echo "Kubernetes Dynatrace cluster: k8s-kind-easytrade-$suffix"
echo ""