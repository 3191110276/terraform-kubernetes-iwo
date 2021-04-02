#!/bin/bash

set -e

# Extract inputs
eval "$(jq -r '@sh "NAMESPACE=\(.namespace)"')"

# Query data
ID=$(kubectl -n iwo -c iwo-k8s-collector exec -it "$(kubectl get pod -n iwo | sed -n 2p | awk '{print $1}')" -- curl -s http://localhost:9110/DeviceIdentifiers | jq '.[].Id')
TOKEN=$(kubectl -n iwo -c iwo-k8s-collector exec -it "$(kubectl get pod -n iwo | sed -n 2p | awk '{print $1}')" -- curl -s http://localhost:9110/SecurityTokens | jq '.[].Token')

ID="${ID%\"}"
ID="${ID#\"}"

TOKEN="${TOKEN%\"}"
TOKEN="${TOKEN#\"}"

# Create output
jq -n --arg id "$ID" --arg token "$TOKEN" '{"id":$id,"token":$token}'
