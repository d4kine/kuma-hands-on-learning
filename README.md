# OCCD Kuma Hands-On-Learning Session

## Preresiquies

The following software needs to be installed:
- `git`
- `docker`
- `kubectl`
- `helm`
- `kubens/kubectx`, `httpie`, `yq`, `jq` (*all optional*)
- `kumactl` (for observability)

**Important**: Your router must allow DNS rebind for the url `nip.io`.
- To setup this in your FRITZ!Box go to `Heimnetz > Netzwerk > Netzwerkeinstellungen` and search for `DNS-Rebind-Schutz` on the bottom of the page

For Windows users please use `WSL/WSL2`.




## Training-Session

### Step 1: Install k3d cluster
```sh
git clone https://github.com/FabianHardt/k3d-bootstrap-cluster
cd k3d-bootstrap-cluster
sudo ./create-sample.sh
```
Don't deploy the HttpBin service. The setup will ask for a few items, just press enter but on `Deploy httpbin sample? (Yes/No) [Yes]:` type `No`
The nginx Ingress is important for this session!

Keep track of the installation if ou want to:
```
watch kubectl get pod,deployment,service,ingress -A --field-selector=metadata.namespace!=kube-system
```

### Step 2: Install Kuma
```sh
git clone https://github.com/d4kine/occd-kuma-hol
cd occd-kuma-hol
sudo ./install.sh
```

After deployment, the Kuma GUI is exposed via ingress via http://kuma.127-0-0-1.nip.io:8080 (or http://localhost:5681/gui/#/ with port-forward)


### Step 2: Deploy demo app
```sh
kubectl apply -f ./manifests/10_demo.yaml
```
Verify the deployment by calling http://frontend.127-0-0-1.nip.io:8080/ (or http://localhost:5000 with port-forward)



### Step 3: Configure TrafficRoutes
*Scenario:* 1 frontend, 3 backends (v0,v1,v2), 1 redis, 1 postgres
- Traffic will be routes 80% to v0, 20% to v1 & 0% v2
- v2 kann mit Header v2 aufgerufen werden

```sh
kubectl apply -f ./manifests/20_traffic-route.yaml
```




### Step 4: Configure mTLS

#### Add Ingress to Mesh
For mTLS it's necessary, that the ingress is included in the mesh. To accomplish that, we will edit the deployment to add a sidecar and tag it as a gateway:
```yaml
spec:
  template:
    metadata:
      labels:
        kuma.io/sidecar-injection: enabled
      annotations:
		kuma.io/gateway: enabled
```

#### Send request into mesh

To test the inactive tls-config, we send a request from another namespace to a mesh-included-service:
```sh
kubectl -n outside-mesh exec -it $(kubectl -n outside-mesh get pods --no-headers -o custom-columns=":metadata.name") -- sh

curl backend.kuma-demo.svc.cluster.local:3001
```



#### Activate mTLS
```
kubectl apply -f mtls.yaml
```

#### Send request into mesh
From outside:
```sh
# from outside
kubectl -n outside-mesh exec -it $(kubectl -n outside-mesh get pods --no-headers -o custom-columns=":metadata.name") -- sh
curl backend.kuma-demo.svc.cluster.local:3001
```

Within the mesh:
```sh
kubectl exec -it $(kubectl -n kuma-demo get pods --no-headers -o custom-columns=":metadata.name" | grep "demo-app-") -c kuma-fe -- sh
curl backend:3001 -vI
```


### Step X: Confiure Observability


### Troubleshooting

In case, that the ingress does not work (maybe dns rebound or config), you can execute the attached script `./port-forward.sh` and use the following URLs:
- For Kuma GUI: http://localhost:5681/gui/#/
- For demo frontend: http://localhost:5000