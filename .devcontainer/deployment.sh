#!/usr/bin/env bash

########################## 
# istio setup
export PATH=$PWD/istio-1.24.0/bin:$PATH
chmod +x istio-1.24.0/bin/istioctl
istioctl install -f istio/istio-operator.yaml --skip-confirmation
kubectl apply -f istio/istio-easytrade.yaml

sleep 30 

##########################
# update istio ingress
kubectl patch svc -n istio-system istio-ingressgateway --patch "$(cat istio/patch.yaml)"
kubectl delete pod --all -n istio-system

##########################
# create easytrade the namespace
kubectl create namespace easytrade

# then use the manifests to deploy
kubectl -n easytrade apply -f easytrade-k8s-manifests
# enable istio on the namespace
kubectl label namespace easytrade istio-injection=enabled
