#!/bin/bash
set -o errexit

helm repo add kuma https://kumahq.github.io/charts
helm repo update

helm upgrade --install kuma kuma/kuma --values cp-standalone-values.yaml --namespace kuma-cp --create-namespace


echo "apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kuma-cp-gui
  namespace: kuma-cp
  annotations:
    nginx.ingress.kubernetes.io/app-root: '/gui'
spec:
  ingressClassName: nginx
  rules:
  - host: kuma.127-0-0-1.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kuma-control-plane
            port:
              number: 5681" | kubectl apply -f -