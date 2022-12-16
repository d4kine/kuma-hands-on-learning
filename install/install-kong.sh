#!/bin/bash

kubectl create namespace kong
kubectl annotate ns kong kuma.io/sidecar-injection="enabled"

helm repo add kong https://charts.konghq.com
helm repo update

helm install kong/kong --generate-name \
    --namespace kong \
    -f kong-cp-values.yaml \
    --set ingressController.installCRDs=false
