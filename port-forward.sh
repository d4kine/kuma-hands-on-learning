#!/bin/sh
kubectl -n kuma port-forward service/kuma-control-plane 5681:5681 & \
kubectl -n kuma-demo port-forward service/frontend 5000:8080 & \

echo ":: Press CTRL-C to stop forwarding"
wait