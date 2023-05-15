#!/bin/bash

kubectl create namespace kong
kubectl annotate ns kong kuma.io/sidecar-injection="enabled"

helm repo add kong https://charts.konghq.com
helm repo update

helm upgrade --install kong kong/kong \
    --version 2.20.2 \
    --namespace kong \
    --values kong-cp-values.yaml \
    --set ingressController.installCRDs=false
