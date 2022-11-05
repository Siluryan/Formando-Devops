# Three node (two workers) cluster config

kind-1m2w-config.yaml:

```
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
```

	kind create cluster --config  kind-1m2w-config.yaml

In kind, we can load images to nodes by kind load command: 

```
docker pull "ghcr.io/fluxcd/helm-controller:v0.21.0"
docker pull "ghcr.io/fluxcd/kustomize-controller:v0.25.0"
docker pull "ghcr.io/fluxcd/notification-controller:v0.23.5"
docker pull "ghcr.io/fluxcd/source-controller:v0.24.4"

```
and load them:

```
kind load docker-image "ghcr.io/fluxcd/helm-controller:v0.21.0"
kind load docker-image "ghcr.io/fluxcd/kustomize-controller:v0.25.0"
kind load docker-image "ghcr.io/fluxcd/notification-controller:v0.23.5"
kind load docker-image "ghcr.io/fluxcd/source-controller:v0.24.4"
```

	flux bootstrap github --owner=$GITHUB_USER   --repository=fleet-infra   --branch=main --path=./clusters/kind-kind   --personal

# Add podinfo repository to Flux

This example uses a public repository github.com/stefanprodan/podinfo, podinfo is a tiny web application made with Go.

Create a GitRepository manifest pointing to podinfo repository’s master branch:

```
flux create source git podinfo \
  --url=https://github.com/stefanprodan/podinfo \
  --branch=master \
  --interval=30s \
  --export > ./clusters/my-cluster/podinfo-source.yaml
```  
  
The output is similar to:

```
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 30s
  ref:
    branch: master
  url: https://github.com/stefanprodan/podinfo
```

	Commit and push the podinfo-source.yaml file to the fleet-infra repository:

```
git add -A && git commit -m "Add podinfo GitRepository"
git push
```

# Deploy podinfo application

Configure Flux to build and apply the kustomize directory located in the podinfo repository.

Use the flux create command to create a Kustomization that applies the podinfo deployment:

```
flux create kustomization podinfo \
  --target-namespace=default \
  --source=podinfo \
  --path="./kustomize" \
  --prune=true \
  --interval=5m \
  --export > ./clusters/my-cluster/podinfo-kustomization.yaml
```
  
The output is similar to:

```
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 5m0s
  path: ./kustomize
  prune: true
  sourceRef:
    kind: GitRepository
    name: podinfo
  targetNamespace: default
```
  
Commit and push the Kustomization manifest to the repository:

```
git add -A && git commit -m "Add podinfo Kustomization"
git push
```

The structure of the fleet-infra repo should be similar to:

```
	fleet-infra
	└── clusters/
	    └── my-cluster/
		├── flux-system/                        
		│   ├── gotk-components.yaml
		│   ├── gotk-sync.yaml
		│   └── kustomization.yaml
		├── podinfo-kustomization.yaml
		└── podinfo-source.yaml
```

# Check podinfo has been deployed on your cluster

kubectl -n default get deployments,services
