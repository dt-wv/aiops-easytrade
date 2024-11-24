#!/bin/bash

read -p "Operator Token: " OPERATOR_TOKEN
read -p "Data ingest Token: " DATA_INGEST_TOKEN
read -p "Tenant ID: " TENANT_ID

# Install
kind create cluster --config .devcontainer/kind-cluster.yml --wait 300s
chmod +x .devcontainer/deployment.sh && source .devcontainer/deployment.sh