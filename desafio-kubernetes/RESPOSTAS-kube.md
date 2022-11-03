1 - com uma unica linha de comando capture somente linhas que contenham "erro" do log do pod serverweb no namespace meusite que tenha a label app: ovo.

    kubectl logs serverweb -n meusite -l app=ovo | grep erro


2 - crie o manifesto de um recurso que seja executado em todos os nós do cluster com a imagem nginx:latest com nome meu-spread, nao sobreponha ou remova qualquer taint de qualquer um dos nós.

    As the way to do it would be the same for nginx, I'll leave the model below for future use.
    If you wanted to do it specifically with Nginx, just replace the values based on the template below    
    https://learn.microsoft.com/pt-br/azure/aks/hybrid/create-daemonsets *tuned for use
    
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
              
3 - crie um deploy meu-webserver com a imagem nginx:latest e um initContainer com a imagem alpine. O initContainer deve criar um arquivo /app/index.html, tenha o conteudo "HelloGetup" e compartilhe com o container de nginx que só poderá ser inicializado se o arquivo foi criado.

        During Pod startup, the kubelet delays running init containers until the networking and storage are ready.
        Then the kubelet runs the Pod's init containers in the order they appear in the Pod's spec.
        Each init container must exit successfully before the next container starts.
        If a container fails to start due to the runtime or exits with failure, it is retried according to the Pod restartPolicy.
        However, if the Pod restartPolicy is set to Always, the init containers use restartPolicy OnFailure.
   
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: meu-webserver
          labels:
            app: nginx
        spec:
          replicas: 3
          selector:
            matchLabels:
              app: nginx
          template:
            metadata:
              labels:
                app: nginx
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
                volumeMounts:
                - name: shared-data
                  mountPath: /app
                command: ['sh', '-c', 'echo HelloGetup > /app/index.html']    
   
        Get a shell to nginx Container:

           - kubectl exec -it meu-webserver -c nginx -- /bin/bash

        In your shell, verify that nginx is running:

            - apt-get update
            - apt-get install curl procps
            - ps aux

        If nginx is running:   

            - curl localhost

        The output shows that nginx serves a web page written by the initContainer:

            HelloGetup