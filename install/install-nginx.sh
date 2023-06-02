#!/bin/bash

kubectl create namespace nginx-ingress
kubectl label namespace nginx-ingress kuma.io/sidecar-injection="enabled"

helm upgrade --install nginx-ingress oci://ghcr.io/nginxinc/charts/nginx-ingress \
    --version 0.17.1 \
    --namespace nginx-ingress
