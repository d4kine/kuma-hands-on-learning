# Kuma Hands-On-Learning Session

Small demo to demonstrate the possibilities with Kuma Service Mesh. The demo application was originally developed by kuma and has the following components:

![image](docs/demo-app.png)

## Preparation

The following software needs to be installed (Windows users please use `WSL/WSL2`):

- `git`
- `docker`
- `kubectl`
- `helm`
- `kubens/kubectx`, `httpie`, `yq`, `jq` (*all optional*)
- `kumactl` (for observability)

You also need to clone this repo (for obvious reasons):

```sh
git clone https://github.com/d4kine/kuma-hands-on-learning
```

> **Important**: Your router must allow DNS rebind for the url `nip.io`.
> - To setup this in your FRITZ!Box go to `Heimnetz > Netzwerk > Netzwerkeinstellungen` and search for `DNS-Rebind-Schutz` on the bottom of the page


## Training session

### Step 1: Setup k3d cluster without Traefik

```sh
k3d cluster create mesh-demo --api-port 127.0.0.1:6445 --servers 1 --agents 2 --port '8088:80@loadbalancer' --k3s-arg '--disable=traefik@server:0'
```

Keep track of the whole installation if you want:
```sh
watch -n 1 kubectl get deployment,pod,service,ingress -A --field-selector=metadata.namespace!=kube-system
```

### Step 2: Install Kuma Mesh

```sh
cd kuma-hands-on-learning/install

./install-kuma.sh
```

### Step 3: Install Ingress Controller

You can choose between nginx and kong as an ingress controller.

> **WARNING**: This demo is based on kong and you need to update the `ingressClassName` parameter the kuma gui and frontend ingress ressource to `nginx`, default value is `kong`.

```sh
# for Kong (default)
./install-kong.sh

# for Nginx (see warning)
./install-nginx.sh
```

After deployment, the Kuma GUI is exposed via ingress via http://kuma.127-0-0-1.nip.io:8088/gui (or http://localhost:5681/gui/#/ with port-forward)

### Step 4: Deploy demo app

```sh
cd ..
kubectl apply -f demo/
```
Verify the deployment by calling http://frontend.127-0-0-1.nip.io:8088 (or http://localhost:5000 with port-forward)

### Step 5: Configure mTLS

#### Add Ingress to Mesh

For mTLS it's necessary, that the ingress controller is leveraged into the mesh. To accomplish that, we only need to restart the kong-pod if it has no side proxy attached yet. To check this, the ready container for kong `kubectl -n kong get po` should sum up in 3 total containers. In case it's not 3, you can restart the pod with:

```sh
kubectl -n kong delete pod --all
```
It may take a few minutes to boot up but afterwards the Jong Ingress-controller should be present as service in the kuma dashboard named `kong-1671179735-kong-proxy_kong_svc_80`
`

#### Send request into mesh

To test the inactive tls-config, we send a request from another namespace to a mesh-included-service:
```sh
kubectl -n outside-mesh exec -it $(kubectl -n outside-mesh get pods --no-headers -o custom-columns=":metadata.name") -- sh

curl backend.kuma-demo.svc.cluster.local:3001
```

#### Activate mTLS

```sh
kubectl apply -f mtls/
```

It's necessary to restart all pods, to generate and distribute the certificates:
```sh
kubectl -n kuma-demo delete pods --all
```

#### Send request into mesh

From outside:
```sh
kubectl -n outside-mesh exec -it $(kubectl -n outside-mesh get pods --no-headers -o custom-columns=":metadata.name") -- sh
curl backend.kuma-demo.svc.cluster.local:3001
```

Within the mesh:
```sh
kubectl -n kuma-demo exec -it $(kubectl -n kuma-demo get pods --no-headers -o custom-columns=":metadata.name" | grep "demo-app-") -c kuma-fe -- sh
curl backend:3001 -vI
```

### Step 6: Configure TrafficPermissions

*Scenario: Connections are only allowed from `Frontend > Backend > Postgres` but not `Backend > Redis`*
- **Requires mTLS and Traffic Permissions are an inbound policies**

```sh
kubectl delete trafficpermissions --all
```

You have to change the proxy service name, otherwise it won't work. Copy it from the Dashboard http://kuma.127-0-0-1.nip.io:8088/gui/#/mesh/default/services and paste it to the permission

```sh
edit traffic-permissions/01_inbound-frontend.yaml

kubectl apply -f traffic-permissions/
```

### Step 7: Configure TrafficRoutes

*Scenario: 1 frontend, 3 backends (v0,v1,v2), 1 redis, 1 postgres*
- Traffic will be routed 80% to v0, 20% to v1 & 0% to v2
- It's only possible to call v2 with the header-atribute: `version: v2`

```sh
kubectl apply -f traffic-routes/
```

### Troubleshooting

In case, that the ingress does not work (maybe DNS rebound or config issues), you can execute the attached script `./port-forward.sh` and use the following URLs:

- For Kuma GUI: http://localhost:5681/gui/#/
- For demo frontend: http://localhost:5000
