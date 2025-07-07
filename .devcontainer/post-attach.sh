#!/usr/bin/env bash

#############################
## Start lab-guide installation
cd lab-guide
# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"
# Download and install Node.js:
nvm install 22

node bin/generator.js
node bin/server.js &
echo ""
echo "Lab Guide running on: https://$CODESPACE_NAME-3000.app.github.dev"
echo ""
cd ..

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

if [ -z "$DT_API_OTEL_TOKEN" ]; then
  read -p 'OTEL API token: ' DT_API_OTEL_TOKEN
else
  echo "DYNATRACE_API_TOKEN has been set"
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
export DT_API_OTEL_TOKEN
export TENANT_ID
export DT_ENDPOINT=$DYNATRACE_ENV_URL"/api/v2/otlp"
suffix=`cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1`
date_suffix=`date +"%Y-%m-%d-%s"`

##########################
# Install Dynatrace
kubectl create namespace dynatrace
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/v1.6.0/kubernetes.yaml
kubectl -n dynatrace wait pod --for=condition=ready --selector=app.kubernetes.io/name=dynatrace-operator,app.kubernetes.io/component=webhook --timeout=120s
kubectl -n dynatrace create secret generic dynakube --from-literal="apiToken=$OPERATOR_TOKEN" --from-literal="dataIngestToken=$DATA_INGEST_TOKEN"

# Application Only without CSI
sed -i "s/REPLACE_NAME/$suffix/g" dynatrace/application.yaml
sed -i "s/REPLACE_TENANT_ID/$TENANT_ID/g" dynatrace/application.yaml

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
# Install Cert Manager & OpenTelemetry
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
sleep 120
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
sleep 120

kubectl apply -f dynatrace/otel-log-collector-clusterrole.yaml
kubectl apply -f dynatrace/otel-log-collector-clusterrole-crb.yaml
kubectl create secret generic dynatrace-otelcol-dt-api-credentials --from-literal=DT_ENDPOINT=$DT_ENDPOINT --from-literal=DT_API_TOKEN=$DT_API_OTEL_TOKEN -n dynatrace
kubectl apply -f dynatrace/otel-log-collector.yaml

## label for oneagent injection and inject per deployment
kubectl label namespace easytrade instrumentation=oneagent
for i in $(kubectl get deployments -n easytrade -o=jsonpath='{.items[*].metadata.name}'); do kubectl rollout restart -n easytrade deployment $i ; sleep 60 ; done


echo ""
echo "[+] Demo installation completed"
echo ""
echo "Kubernetes Dynatrace cluster: k8s-kind-easytrade-$suffix"
echo ""
echo "Lab Guide running on: https://$CODESPACE_NAME-3000.app.github.dev"