### 1 - com uma unica linha de comando capture somente linhas que contenham "erro" do log do pod serverweb no namespace meusite que tenha a label app: ovo.
```bash
  kubectl logs serverweb -n meusite -l app=ovo | grep -i erro
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

#### 4.1 Add a label to a node:
  

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

  
#### 4.2 Create a pod that gets scheduled to your chose:  

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

##### The following command specifies both the resource that will be affected and its respective container, so the key with the name nginx appears only by coincidence, and its real meaning is the name of the container in which you want to change the image.

```bash
  kubectl set image pod/meuweb nginx=nginx:1.19
```

Ref:

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-image-em-


### 6 - quais linhas de comando para instalar o ingress-nginx controller usando helm, com os seguintes parametros:

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

### 7 - quais as linhas de comando para:

#### 7.1 - criar um deploy chamado `pombo` com a imagem de `nginx:1.11.9-alpine` com 4 réplicas:

Example:
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
Command:
```bash
kubectl create deployment pombo --image=nginx:1.11.9-alpine --replicas=4
```

#### 7.2 - alterar a imagem para `nginx:1.16` e registre na annotation automaticamente:

```bash
kubectl set image deployment/pombo pombo-container=nginx:1.16 && kubectl annotate deploy pombo kubernetes.io/change-cause="version change to 1.16" 
```

#### 7.3 - alterar a imagem para 1.19 e registre novamente:

```bash
kubectl set image deployment/pombo pombo-container=nginx:1.19 && kubectl annotate deploy pombo kubernetes.io/change-cause="version change to 1.19" 
```

#### 7.4 - imprimir a historia de alterações desse deploy:

```bash
kubectl rollout history deployment pombo
```

#### 7.5 - voltar para versão 1.11.9-alpine baseado no historico que voce registrou:

```bash
kubectl rollout undo deployment/pombo --to-revision=Nº
```

#### 7.6 - criar um ingress chamado `web` para esse deploy:

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

Expose the previously created Deployment:

```bash
kubectl expose deploy/pombo --type=NodePort # LoadBalancer wont't work in Kind or Minikube deployments (https://docs.k0sproject.io/v1.23.6+k0s.2/cloud-providers/)
```

Example:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web 
spec:
  ingressClassName: nginx
  rules:
  - host: pombodevops.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
```

Command:
```bash
 kubectl create ingress web --rule="pombodevops.com/=pombo:80"
```

Ref:

https://blog.knoldus.com/how-to-create-ingress-rules-in-kubernetes-using-minikube/

https://stackoverflow.com/questions/73814500/record-has-been-deprecated-then-what-is-the-alternative

https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-0AADC6F0-C29A-4B33-909D-6B95476EA332.html

https://docs.k0sproject.io/v1.23.6+k0s.2/examples/nginx-ingress/

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-deployment-em-

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-ingress-em-

https://kubernetes.io/pt-br/docs/reference/kubectl/cheatsheet/

https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

https://kubernetes.io/docs/concepts/services-networking/ingress/

https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/



### 8 - linhas de comando para:

#### 8.1 - criar um deploy chamado `guardaroupa` com a imagem `redis`:

```bash
kubectl create deployment guardaroupa --image=redis
```
#### 8.2 - criar um serviço do tipo ClusterIP desse redis com as devidas portas:

```bash
kubectl expose deployment guardaroupa --type ClusterIP --port 6379
```

Ref:

https://redis.io/docs/getting-started/

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-deployment-em-

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#expose

### 9 - crie um recurso para aplicação stateful com os seguintes parametros:

```
nome : meusiteset
imagem: nginx 
namespace: backend
3 réplicas
disco de 1Gi
montado em /data
sufixo dos pvc: data-pvc
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: meusiteset
  labels:
    app: nginx 
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: meusiteset
  namespace: backend
spec:  
  selector:
    matchLabels:
      app: nginx # has to match .spec.template.metadata.labels
  serviceName: "meusiteset"
  replicas: 3 # by default is 1
  minReadySeconds: 10 # by default is 0
  template:
    metadata:
      labels:
        app: nginx # has to match .spec.selector.matchLabels
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: data-pv
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: data-pvc
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "ebs"
      resources:
        requests:
          storage: 1Gi
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  fsType: ext4
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: backend
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  selector:
    matchLabels:
      type: local      
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-pv
  namespace: backend
  labels:
    type: local
spec:
  storageClassName: "ebs"
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
  claimRef:
    name: data-pvc
    namespace: backend
```

Ref:

https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/

https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/

https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes

### 10 - crie um recurso com 2 replicas, chamado `balaclava` com a imagem `redis`, usando as labels nos pods, replicaset e deployment, `backend=balaclava` e `minhachave=semvalor` no namespace `backend`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: balaclava
  namespace: backend
  labels:
    backend: balaclava
    minhachave: semvalor
spec:
  replicas: 2
  selector:
    matchLabels:
      backend: balaclava
      minhachave: semvalor
  template:
    metadata:
      labels:
        backend: balaclava
        minhachave: semvalor  
    spec:
      containers:
      - name: balaclava-container
        image: redis
        ports:
        - containerPort: 6379
```

Ref:

https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/


### 11 - linha de comando para listar todos os serviços do cluster do tipo `LoadBalancer` mostrando tambem `selectors`.

#### 11.1 - First install jq in your local machine. jq is a lightweight and flexible command-line JSON processor

```bash
sudo apt install jq
```

#### 11.2 - Command:
```bash
kubectl get services -o json | jq -r '.items[] | select(.spec.type | "LoadBalancer").metadata.name,.spec.selector'
```
Ref:

https://kubernetes.io/docs/reference/kubectl/jsonpath/

### 12 - com uma linha de comando, crie uma secret chamada meusegredo no namespace segredosdesucesso com os dados, segredo=azul e com o conteudo do texto abaixo.

```bash
  # cat chave-secreta
    aW5ncmVzcy1uZ2lueCAgIGluZ3Jlc3MtbmdpbngtY29udHJvbGxlciAgICAgICAgICAgICAgICAg
    ICAgICAgICAgICAgTG9hZEJhbGFuY2VyICAgMTAuMjMzLjE3Ljg0ICAgIDE5Mi4xNjguMS4zNSAg
    IDgwOjMxOTE2L1RDUCw0NDM6MzE3OTQvVENQICAgICAyM2ggICBhcHAua3ViZXJuZXRlcy5pby9j
    b21wb25lbnQ9Y29udHJvbGxlcixhcHAua3ViZXJuZXRlcy5pby9pbnN0YW5jZT1pbmdyZXNzLW5n
    aW54LGFwcC5rdWJlcm5ldGVzLmlvL25hbWU9aW5ncmVzcy1uZ
```
#### Command:
```bash
  kubectl create namespace segredosdesucesso && \
  kubectl create secret -n segredosdesucesso generic meusegredo \
  --from-literal=segredo=azul \
  --from-file=./secret.txt 
```
Ref:

https://kubernetes.io/docs/concepts/configuration/secret/

https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/

### 13 - qual a linha de comando para criar um configmap chamado configsite no namespace site. Deve conter uma entrada index.html que contenha seu nome.

#### Command:
```bash
kubectl create namespace site && \
kubectl create configmap configsite -n site \
--from-literal=index.html=seunome
```
Ref:

https://kubernetes.io/docs/concepts/configuration/configmap/

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-configmap-em-

### 14 - crie um recurso chamado meudeploy, com a imagem nginx:latest, que utilize a secret criada no exercicio 11 como arquivos no diretorio /app.
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: meudeploy
  namespace: segredosdesucesso  
  labels:
    app: meudeploy
spec:
  selector:
    matchLabels:
      app: meudeploy
  replicas: 1
  template:
    metadata:
      labels:
        app: meudeploy
    spec:
      volumes:
      - name: secret-volume
        secret:
          secretName: meusegredo
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: secret-volume
          readOnly: true
          mountPath: "/app"      
```
Ref:

https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/

https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-files-from-a-pod

### 15 - crie um recurso chamado depconfigs, com a imagem nginx:latest, que utilize o configMap criado no exercicio 12 e use seu index.html como pagina principal desse recurso.
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: depconfigs
  namespace: site
  labels:
    app: depconfigs
spec:
  replicas: 1
  selector:
    matchLabels:
      app: depsconfigs
  template:
    metadata:
      labels:
        app: depsconfigs
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: /usr/share/nginx/html
          name: configmap 
      volumes:
      - name: configmap
        configMap:
          name: configsite
```
Ref:

https://scriptcrunch.com/change-nginx-index-configmap/

https://kubernetes.io/docs/concepts/configuration/configmap/

https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/

### 16 - crie um novo recurso chamado meudeploy-2 com a imagem nginx:1.16 , com a label chaves=secretas e que use todo conteudo da secret como variavel de ambiente criada no exercicio 12.


```yaml
apiVersion: apps/v1
kind: Deployment
metadata:  
  labels:
    app: meudeploy-2
    chaves: secretas
  name: meudeploy-2
  namespace: segredosdesucesso
spec:
  replicas: 1
  selector:
    matchLabels:
      app: meudeploy-2
      chaves: secretas
  template:
    metadata:     
      labels:
        app: meudeploy-2
        chaves: secretas
    spec:
      containers:
      - image: nginx:1.16
        name: nginx
        envFrom:          
        - secretRef:  
            name: meusegredo                     
```
Ref:

https://spacelift.io/blog/kubernetes-secrets

https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#define-container-environment-variables-using-secret-data

### 17 - linhas de comando que;

```bash
crie um namespace `cabeludo`;
um deploy chamado `cabelo` usando a imagem `nginx:latest`; 
uma secret chamada `acesso` com as entradas `username: pavao` e `password: asabranca`;
exponha variaveis de ambiente chamados USUARIO para username e SENHA para a password.
```

```bash
kubectl create namespace cabeludo
kubectl -n cabeludo create deployment cabelo --image=nginx:latest
kubectl -n cabeludo create secret generic acesso --from-literal=username=pavao --from-literal=password=asabranca
kubectl -n cabeludo set env deploy/cabelo USUARIO=$(kubectl get secret acesso -o jsonpath='{.data.username}' | base64 --decode) SENHA=$(kubectl get secret acesso -o jsonpath='{.data.password}' | base64 --decode)
```
Ref:

https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#set

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-env-em-

### 18 - crie um deploy redis usando a imagem com o mesmo nome, no namespace cachehits e que tenha o ponto de montagem /data/redis de um volume chamado app-cache que NÂO deverá ser persistente.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: redis
  name: redis
  namespace: cachehits
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - image: redis
        name: redis
        volumeMounts:
        - mountPath: /data/redis
          name: app-cache
      volumes:
      - name: app-cache
        emptyDir:
          sizeLimit: 250Mi
```
 Ref:

 https://kubernetes.io/docs/concepts/storage/volumes/#emptydir

### 19 - com uma linha de comando escale um deploy chamado basico no namespace azul para 10 replicas.
```bash
kubectl -n azul scale --replicas=10 deploy/basico
```
Ref:

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#scale

### 20 - com uma linha de comando, crie um autoscale de cpu com 90% de no minimo 2 e maximo de 5 pods para o deploy site no namespace frontend.
```bash
kubectl -n frontend autoscale deploy/site --min=2 --max=5 --cpu-percent=90
```

Ref:

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#autoscale

### 21 - com uma linha de comando, descubra o conteudo da secret piadas no namespace meussegredos com a entrada segredos.
```bash
kubectl -n meussegredos get secret piadas -o jsonpath='{.data.segredos}' | base64 -d
```
Ref:

https://kubernetes.io/docs/concepts/configuration/secret/

### 22 - marque o node k8s-worker1 do cluster para que nao aceite nenhum novo pod.

```bash
kubectl taint nodes k8s-worker1 key1=value1:NoSchedule

or...

kubectl cordon k8s-worker1
```
Ref:

https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#cordon

### 23 - esvazie totalmente e de uma unica vez esse mesmo nó com uma linha de comando.
```bash
kubectl drain k8s-worker1 --force
```
Ref:

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#drain

### 24 - qual a maneira de garantir a criaçao de um pod (sem usar o kubectl ou api do k8s) em um nó especifico.

#### 24.1 - Manifests are standard Pod definitions in JSON or YAML format in a specific directory. Use the staticPodPath: <the directory> field in the kubelet configuration file, which periodically scans the directory and creates/deletes static Pods as YAML/JSON files appear/disappear there. Note that the kubelet will ignore files starting with dots when scanning the specified directory.

#### 24.1.1 - Choose a node where you want to run the static Pod. In this example, it's my-node1.

```bash
ssh my-node1
```

#### 24.1.2 - Choose a directory, say /etc/kubernetes/manifests and place a web server Pod definition there, for example /etc/kubernetes/manifests/static-web.yaml:

```bash
mkdir -p /etc/kubernetes/manifests/
```
```bash
cat <<EOF >/etc/kubernetes/manifests/static-web.yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-web
  labels:
    role: myrole
spec:
  containers:
    - name: web
      image: nginx
      ports:
        - name: web
          containerPort: 80
          protocol: TCP
EOF
```

#### 24.1.3 - Configure your kubelet on the node to use this directory by running it with --pod-manifest-path=/etc/kubernetes/manifests/ argument.

```bash
KUBELET_ARGS="--cluster-dns=10.254.0.10 --cluster-domain=kube.local --pod-manifest-path=/etc/kubernetes/manifests/"
```

#### 24.1.4 - Restart the kubelet.

```bash
systemctl restart kubelet
```

#### 24.2 - Kubelet periodically downloads a file specified by --manifest-url=<URL> argument and interprets it as a JSON/YAML file that contains Pod definitions. Similar to how filesystem-hosted manifests work, the kubelet refetches the manifest on a schedule. If there are changes to the list of static Pods, the kubelet applies them.

#### 24.2.1 - Create a YAML file and store it on a web server so that you can pass the URL of that file to the kubelet.
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-web
  labels:
    role: myrole
spec:
  containers:
    - name: web
      image: nginx
      ports:
        - name: web
          containerPort: 80
          protocol: TCP

```
#### 24.2.2 - Configure the kubelet on your selected node to use this web manifest by running it with --manifest-url=<manifest-url>.
```bash
KUBELET_ARGS="--cluster-dns=10.254.0.10 --cluster-domain=kube.local --manifest-url=<manifest-url>"
```
#### 24.2.3 - Restart the kubelet

```bash
systemctl restart kubelet
```

Ref:

https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/

### 25 - criar uma serviceaccount userx no namespace developer. essa serviceaccount só pode ter permissao total sobre pods (inclusive logs) e deployments no namespace developer. descreva o processo para validar o acesso ao namespace do jeito que achar melhor.

A Role always sets permissions within a particular namespace; when you create a Role, you have to specify the namespace it belongs in.

Pods is the namespaced resource for Pod resources, and log is a subresource of pods. To represent this in an RBAC role, use a slash (/) to delimit the resource and subresource.

You can still manually create a service account token Secret; for example, if you need a token that never expires. However, using the TokenRequest subresource to obtain a token to access the API is recommended instead.

If you want to obtain an API token for a ServiceAccount, you create a new Secret with a special annotation, kubernetes.io/service-account.name.

A RoleBinding or ClusterRoleBinding binds a role to subjects. Subjects can be groups, users or ServiceAccounts.

If you are not sure if your (or another) user is allowed to do a certain action, you can verify that with the kubectl auth can-i command.

```yaml
# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: developer
---
# serviceAccount
apiVersion: v1
kind: ServiceAccount
metadata:  
  name: userx
  namespace: developer
---
# token
apiVersion: v1
kind: Secret
metadata:
  name: userx-token
  namespace: developer
  annotations:
    kubernetes.io/service-account.name: userx
type: kubernetes.io/service-account-token
---
# role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: developer
  name: all-requests-dev-ns
rules:
- apiGroups: ["","apps"] 
  resources: ["pods", "pods/log","deployments"]
  verbs: ["create", "get", "watch", "list", "update", "patch", "delete", "deletecollection"]
---
# roleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: developer
  name: bind-userx-all-req  
subjects:
- kind: User
  name: userx # Name is case sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: all-requests-dev-ns
  apiGroup: rbac.authorization.k8s.io
```
Command to verify userx can deploy in the developer namespace:
```bash
kubectl auth can-i create deployments \
--namespace developer \
--as userx
```
Ref:

https://docs.giantswarm.io/getting-started/rbac-and-psp/

https://kubernetes.io/docs/reference/access-authn-authz/authorization/

https://kubernetes.io/docs/reference/access-authn-authz/authentication/

https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/

https://kubernetes.io/docs/reference/access-authn-authz/rbac/

### 26 - criar a key e certificado cliente para uma usuaria chamada jane e que tenha permissao somente de listar pods no namespace frontend. liste os comandos utilizados.

#### 26.1 - Create private key:
```bash
openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -out jane.csr
```
#### 26.2 - Command to get base64 encoded value of the CSR request parameter in file content:
```bash
cat jane.csr | base64 | tr -d "\n"
```
#### 26.3 - Create CertificateSigningRequest:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: jane
spec:
  request: PUT HERE THE ENCODED VALUE FROM PREVIOUS STEP, WITHOUT QUOTES
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF
```
#### 26.4 - Approve the CSR:
```bash
kubectl certificate approve jane
```
#### 26.5 - Export the issued certificate from the CertificateSigningRequest (the certificate value is in Base64-encoded format under status.certificate).
```bash
kubectl get csr jane -o jsonpath='{.status.certificate}'| base64 -d > jane.crt
```
#### 26.6 - Create Role and RoleBinding:
```bash
kubectl -n frontend create role jane-role --verb=list --resource=pods --namespace=frontend
kubectl -n frontend create rolebinding jane-rolebinding --role=jane-role --user=jane
```

#### 26.7 - Add new credentials to kubeconfig:
```bash
kubectl config set-credentials jane --client-key=jane.key --client-certificate=jane.crt --embed-certs=true
```
#### 26.8 - Add the context:
```bash
kubectl config set-context jane --cluster=kubernetes --user=jane
```
Ref:

https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-role-em-





