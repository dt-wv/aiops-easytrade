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
# create easytrade the namespace
kubectl create namespace easytrade

# then use the manifests to deploy
kubectl -n easytrade apply -f easytrade-k8s-manifests

# Optional: if you want the problem patterns to be automatically
# enabled once a day, deploy these manifests too
kubectl -n easytrade apply -f easytrade-k8s-manifests/problem-patterns
kubectl label namespace easytrade istio-injection=enabled
