### 1 - com uma unica linha de comando capture somente linhas que contenham "erro" do log do pod serverweb no namespace meusite que tenha a label app: ovo.
```bash
  kubectl logs serverweb -n meusite -l app=ovo | grep erro
```
 
Ref:

https://kubernetes.io/docs/reference/kubectl/cheatsheet/


### 2 - crie o manifesto de um recurso que seja executado em todos os nós do cluster com a imagem nginx:latest com nome meu-spread, nao sobreponha ou remova qualquer taint de qualquer um dos nós.
```
As the way to do it would be the same for nginx, I'll leave the model below for future use.
If you want to do it specifically with nginx, as well to follow the exercise requirements,
just replace the values based on the template below.
```
    
Ref:

https://learn.microsoft.com/pt-br/azure/aks/hybrid/create-daemonsets  *tuned for use

    
```yaml
apiVersion: apps/v1  
kind: DaemonSet  
metadata: 
  name: nginx 
  labels: 
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:  
      containers:  
      - name: nginx  
        image: nginx
```
```
A DaemonSet ensures that all (or some) Nodes run a copy of a Pod. As nodes are added to the cluster,
Pods are added to them. As nodes are removed from the cluster, those Pods are garbage collected.
Deleting a DaemonSet will clean up the Pods it created. A DaemonSet ensures that all eligible nodes
run a copy of a Pod. Normally, the node that a Pod runs on is selected by the Kubernetes scheduler.
However, DaemonSet pods are created and scheduled by the DaemonSet controller instead.
That introduces the following issues:

- Inconsistent Pod behavior:

  Normal Pods waiting to be scheduled are created and in Pending state, but DaemonSet pods are not created
  in Pending state.

- Pod preemption is handled by default scheduler:

  When preemption is enabled, the DaemonSet controller will make scheduling decisions without considering
  pod priority and preemption.

ScheduleDaemonSetPods allows you to schedule DaemonSets using the default scheduler instead of the DaemonSet
controller, by adding the NodeAffinity term to the DaemonSet pods, instead of the .spec.nodeName term.
The default scheduler is then used to bind the pod to the target host. If node affinity of the DaemonSet pod
already exists, it is replaced (the original node affinity was taken into account before selecting the target host).
The DaemonSet controller only performs these operations when creating or modifying DaemonSet pods,
and no changes are made to the spec.template of the DaemonSet.

Daemon Pods respect taints and tolerations.
```
```yaml    
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-elasticsearch
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd-elasticsearch
  template:
    metadata:
      labels:
        name: fluentd-elasticsearch
    spec:
      affinity:
      # ScheduleDaemonSetPods
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchFields:
              - key: metadata.name
                operator: In
                values:
                  - target-host-name
      tolerations:
      # these tolerations are to have the daemonset runnable on control plane nodes
      # remove them if your control plane nodes should not run pods
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      containers:
      - name: fluentd-elasticsearch
        image: quay.io/fluentd_elasticsearch/fluentd:v2.5.2
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
```

Ref:

https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/

https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/
 
              
### 3 - crie um deploy meu-webserver com a imagem nginx:latest e um initContainer com a imagem alpine. O initContainer deve criar um arquivo /app/index.html, tenha o conteudo "HelloGetup" e compartilhe com o container de nginx que só poderá ser inicializado se o arquivo foi criado.

```
During Pod startup, the kubelet delays running init containers until the networking and storage are ready.
Then the kubelet runs the Pod's init containers in the order they appear in the Pod's spec.
Each init container must exit successfully before the next container starts.
If a container fails to start due to the runtime or exits with failure, it is retried according to the Pod
restartPolicy. However, if the Pod restartPolicy is set to Always, the init containers use restartPolicy OnFailure.

An emptyDir volume is first created when a Pod is assigned to a node, and exists as long as that Pod is running
on that node. As the name says, the emptyDir volume is initially empty. All containers in the Pod can read and write
the same files in the emptyDir volume, though that volume can be mounted at the same or different paths
in each container. When a Pod is removed from a node for any reason, the data in the emptyDir is deleted permanently.

Note: A container crashing does not remove a Pod from a node. The data in an emptyDir volume is safe across
container crashes.
```   
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: meu-webserver
spec:
  selector:
    matchLabels:
      app: meu-webserver
  template:
    metadata:
      labels:
        app: meu-webserver
    spec:                        
      volumes:
      - name: shared-data
        emptyDir: {}
      containers:
      - name: nginx
        image: nginx:latest
        ports:
          - containerPort: 80
        volumeMounts:
        - name: shared-data
          mountPath: /usr/share/nginx/html            
      initContainers:
      - name: init-myservice
        image: alpine 
        command: ['sh', '-c', 'echo HelloGetup > /app/index.html']
        volumeMounts:
        - name: shared-data
          mountPath: /app
```
   
    Get a shell to "meu-webserver" deployment:

        kubectl exec -it deploy/meu-webserver -- /bin/bash

    In your shell try this command:

        curl localhost

    The output shows that nginx serves a web page written by the initContainer:

        "HelloGetup"
        
Ref:

https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/

https://kubernetes.io/docs/concepts/storage/volumes/

https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/

https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/

https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-initialization/


### 4 - crie um deploy chamado meuweb com a imagem nginx:1.16 que seja executado exclusivamente no node master.
```
NodeSelector is the simplest recommended form of node selection constraint.
You can add the nodeSelector field to your Pod specification and specify the node labels
you want the target node to have. Kubernetes only schedules the Pod onto nodes that have
each of the labels you specify.
```
  
### 4.1 Add a label to a node:
  

    List the nodes in your cluster, along with their labels:

      kubectl get nodes --show-labels

    The output is similar to this:

    NAME      STATUS    ROLES    AGE     VERSION        LABELS
    worker0   Ready     <none>   1d      v1.13.0        ...,kubernetes.io/hostname=worker0
    worker1   Ready     <none>   1d      v1.13.0        ...,kubernetes.io/hostname=worker1
    worker2   Ready     <none>   1d      v1.13.0        ...,kubernetes.io/hostname=worker2
    
    Choose one of your nodes, and add a label to it:

      kubectl label nodes <your-node-name> node=master (where <your-node-name> is the name of your chosen node)    

    Verify that your chosen node has a node=master label:

      kubectl get nodes --show-labels

    The output is similar to this:

    NAME      STATUS    ROLES    AGE     VERSION        LABELS
    worker0   Ready     <none>   1d      v1.13.0        ...,node=master,kubernetes.io/hostname=worker0
    worker1   Ready     <none>   1d      v1.13.0        ...,kubernetes.io/hostname=worker1
    worker2   Ready     <none>   1d      v1.13.0        ...,kubernetes.io/hostname=worker2
    
    In the preceding output, you can see that the worker0 node has a node=master label.

  
### 4.2 Create a pod that gets scheduled to your chose:  

    This pod configuration file describes a pod that has a node selector, node: master.
    This means that the pod will get scheduled on a node that has a node=master label.

```yaml
Pod example:

apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    node: master

Deployment example:

apiVersion: apps/v1
kind: Deployment
metadata:
  name: meuweb
  labels:
    app: nginx
spec:
  replicas: 1 
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec: 
      # Put here the label you applied to node master
      nodeSelector:
        node: master 
      containers:
        - name: nginx
          image: nginx:1.16
          ports:
            - containerPort: 80
```
Ref:

https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/

https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/

### 5 - com uma unica linha de comando altere a imagem desse pod meuweb para nginx:1.19 e salve o comando aqui no repositorio.
```
The following command specifies both the resource that will be affected and its respective container,
so the key with the name nginx appears only by coincidence, and its real meaning is the name
of the container in which you want to change the image.
```
```bash
  kubectl set image pod/meuweb nginx=nginx:1.19
```

Ref:

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-image-em-


### 6 - quais linhas de comando para instalar o ingress-nginx controller usando helm, com os seguintes parametros;

```
helm repository : https://kubernetes.github.io/ingress-nginx

values do ingress-nginx : 
controller:
  hostPort:
    enabled: true
  service:
    type: NodePort
  updateStrategy:
    type: Recreate
```

To install a new package, use the helm install command. At its simplest, it takes two arguments: A release name that you pick, and the name of the chart you want to install.

Multiple values are separated by , characters. So --set a=b,c=d becomes:

```
a: b
c: d
```
More complex expressions are supported. For example,
--set outer.inner=value is translated into this:

```
outer:
  inner: value
```


```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
 
helm repo update

helm install [release_name] ingress-nginx/ingress-nginx --set controller.hostPort.enable=true,controller.service.type=NodePort,controller.updateStrategy.type=Recreate

or... 

helm install --generate-name ingress-nginx/ingress-nginx --set controller.hostPort.enable=true,controller.service.type=NodePort,controller.updateStrategy.type=Recreate

or also...

helm install --generate-name ingress-nginx/ingress-nginx  \
--set controller.hostPort.enable=true \
--set controller.service.type=NodePort \
--set controller.updateStrategy.type=Recreate
```
Ref:

https://kubernetes.github.io/ingress-nginx/

https://helm.sh/docs/intro/using_helm/

https://helm.sh/docs/helm/helm_install/

### 7.1 - criar um deploy chamado `pombo` com a imagem de `nginx:1.11.9-alpine` com 4 réplicas:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pombo
  labels:
    app: pombo
spec:
  replicas: 4
  selector:
    matchLabels:
      app: pombo
  template:
    metadata:
      labels:
        app: pombo
    spec:
      containers:
      - name: pombo-container
        image: nginx:1.11.9-alpine
        ports:
        - containerPort: 80
```
### 7.2 - alterar a imagem para `nginx:1.16` e registre na annotation automaticamente:

```bash
kubectl set image deployment/pombo pombo-container=nginx:1.16 && kubectl annotate deploy pombo kubernetes.io/change-cause="version change to 1.16" 
```

### 7.3 - alterar a imagem para 1.19 e registre novamente:

```bash
kubectl set image deployment/pombo pombo-container=nginx:1.19 && kubectl annotate deploy pombo kubernetes.io/change-cause="version change to 1.19" 
```

### 7.4 - imprimir a historia de alterações desse deploy:

```bash
kubectl rollout history deployment pombo
```

### 7.5 - voltar para versão 1.11.9-alpine baseado no historico que voce registrou:

```bash
kubectl rollout undo deployment/pombo --to-revision=Nº
```

### 7.6 - criar um ingress chamado `web` para esse deploy:

You must have an Ingress controller to satisfy an Ingress. Only creating an Ingress resource has no effect.

Installing Helm.

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

chmod 700 get_helm.sh

./get_helm.sh
```
------------------------------------------------

This step is required if you’re installing the chart via the helm repository.

```bash
helm repo add nginx-stable https://helm.nginx.com/stable

helm repo update
```

-------------------------------------------------

By default, the Ingress Controller requires a number of custom resource definitions (CRDs) installed in the cluster. The Helm client will install those CRDs. If the CRDs are not installed, the Ingress Controller pods will not become Ready.

```bash
helm install nginx-ingress-controller nginx-stable/nginx-ingress
```
--------------------------------------------------

A minimal Ingress resource example:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx-web
  rules:
  - http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80
```

----------------------------------------------------

```bash
kubectl apply -f ingress-web.yaml
```


Ref:

https://stackoverflow.com/questions/73814500/record-has-been-deprecated-then-what-is-the-alternative

https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-0AADC6F0-C29A-4B33-909D-6B95476EA332.html

https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/

https://kubernetes.io/pt-br/docs/reference/kubectl/cheatsheet/