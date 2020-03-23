# 集群管理：以 Redis 为例-部署及访问

**Pod 是 K8S 中最小的调度单元，所以我们无法直接在 K8S 中运行一个 container 但是我们可以运行一个 Pod 而这个 Pod 中只包含一个 container** 

## 使用最小的 Redis 镜像

在 Redis 的[官方镜像列表](https://hub.docker.com/_/redis/)可以看到有很多的 tag 可供选择，其中使用 [Alpine Linux](https://alpinelinux.org/) 作为基础的镜像体积最小，下载较为方便。我们选择 `redis:alpine` 这个镜像进行部署

## 部署

```shell
[root@localhost ~]# kubectl run redis --image='redis:alpine'
deployment.apps/redis created
```

kubectl get all可以看到redis的pod已经创建

```shell
[root@localhost ~]# kubectl get all
NAME                         READY     STATUS    RESTARTS   AGE
pod/redis-7c7545cbcb-npb9r   0/1       Pending   0          45s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   22m

NAME                    DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/redis   1         1         1            0           46s

NAME                               DESIRED   CURRENT   READY     AGE
replicaset.apps/redis-7c7545cbcb   1         1         0         46s

```



```
[root@localhost .kube]# kubectl get pods
NAME                     READY     STATUS    RESTARTS   AGE
redis-7c7545cbcb-npb9r   0/1       Pending   0          1h
[root@localhost .kube]# kubectl describe pod redis-7c7545cbcb-npb9r
Name:               redis-7c7545cbcb-npb9r
Namespace:          default
Priority:           0
PriorityClassName:  <none>
Node:               <none>
Labels:             pod-template-hash=3731017676
                    run=redis
Annotations:        <none>
Status:             Pending
IP:                 
Controlled By:      ReplicaSet/redis-7c7545cbcb
Containers:
  redis:
    Image:        redis:alpine
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-d8mnt (ro)
Conditions:
  Type           Status
  PodScheduled   False 
Volumes:
  default-token-d8mnt:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-d8mnt
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type     Reason            Age                 From               Message
  ----     ------            ----                ----               -------
  Warning  FailedScheduling  2m (x9968 over 1h)  default-scheduler  0/1 nodes are available: 1 node(s) had taints that the pod didn't tolerate.
```



### Deployment

`Deployment` 是一种高级别的抽象，允许我们进行扩容，滚动更新及降级等操作。我们使用 `kubectl run redis --image='redis:alpine` 命令便创建了一个名为 `redis` 的 `Deployment`，并指定了其使用的镜像为 `redis:alpine`。

```shell
[root@localhost ~]# kubectl get deployment.apps/redis -o wide 
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS   IMAGES         SELECTOR
redis     1         1         1            0           6m        redis        redis:alpine   run=redis
```

同时 K8S 会默认为其增加一些标签（`Label`）。我们可以通过更改 `get` 的输出格式进行查看。

```shell
[root@localhost ~]# kubectl get deployment.apps/redis -o wide 
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS   IMAGES         SELECTOR
redis     1         1         1            0           6m        redis        redis:alpine   run=redis
```

我们在应用部署或更新时总是会考虑的一个问题是如何平滑升级，利用 `Deployment` 也能很方便的进行金丝雀发布（Canary deployments）。这主要也依赖 `Label` 和 `Selector`，

### ReplicaSet

`ReplicaSet` 是一种较低级别的结构，允许进行扩容。

我们上面已经提到 `Deployment` 主要是声明一种预期的状态，并且会将 `Pod` 托管给 `ReplicaSet`，而 `ReplicaSet` 则会去检查当前的 `Pod` 数量及状态是否符合预期，并尽量满足这一预期。

`ReplicaSet` 可以由我们自行创建，但一般情况下不推荐这样去做，因为如果这样做了，那其实就相当于跳过了 `Deployment` 的部分，`Deployment` 所带来的功能或者特性我们便都使用不到了

`ReplicaSet` 可简写为 `rs`，通过以下命令查看：

```shell
[root@localhost ~]# kubectl get rs -o wide
NAME               DESIRED   CURRENT   READY     AGE       CONTAINERS   IMAGES         SELECTOR
redis-7c7545cbcb   1         1         0         29m       redis        redis:alpine   pod-template-hash=3731017676,run=redis
```

的 `run=redis` 标签外，还多了一个 `pod-template-hash=3731017676` 标签，这个标签是由 `Deployment controller` 自动添加的，目的是为了防止出现重复，所以将 `pod-template` 进行 hash 用作唯一性标识

### Service

`Service` 简单点说就是为了能有个稳定的入口访问我们的应用服务或者是一组 `Pod`。通过 `Service` 可以很方便的实现服务发现和负载均衡。

```shell
[root@localhost ~]#  kubectl get service -o wide
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE       SELECTOR
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   53m       <none>
```

### 类型

`Service` 目前有 4 种类型：

- `ClusterIP`： 是 K8S 当前默认的 `Service` 类型。将 service 暴露于一个仅集群内可访问的虚拟 IP 上。
- `NodePort`： 是通过在集群内所有 `Node` 上都绑定固定端口的方式将服务暴露出来，这样便可以通过 `:` 访问服务了。
- `LoadBalancer`： 是通过 `Cloud Provider` 创建一个外部的负载均衡器，将服务暴露出来，并且会自动创建外部负载均衡器路由请求所需的 `Nodeport` 或 `ClusterIP` 。
- `ExternalName`： 是通过将服务由 DNS CNAME 的方式转发到指定的域名上将服务暴露出来，这需要 `kube-dns` 1.7 或更高版本支持。

### 实践

上面已经说完了 `Service` 的基本类型，而我们也已经部署了一个 Redis ,当还无法访问到该服务，接下来我们将刚才部署的 Redis 服务暴露出来

```shell
[root@localhost ~]#  kubectl expose deploy/redis --port=6379 --protocol=TCP --target-port=6379 --name=redis-server  
service/redis-server exposed
[root@localhost ~]# kubectl get svc -o wide   
NAME           TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE       SELECTOR
kubernetes     ClusterIP   10.96.0.1      <none>        443/TCP    57m       <none>
redis-server   ClusterIP   10.101.37.89   <none>        6379/TCP   12s       run=redis
```

通过 `kubectl expose` 命令将 redis server 暴露出来，这里需要进行下说明：

- `port`： 是 `Service` 暴露出来的端口，可通过此端口访问 `Service`。
- `protocol`： 是所用协议。当前 K8S 支持 TCP/UDP 协议，在 1.12 版本中实验性的加入了对 [SCTP 协议](https://zh.wikipedia.org/zh-hans/流控制传输协议)的支持。默认是 TCP 协议。
- `target-port`： 是实际服务所在的目标端口，请求由 `port` 进入通过上述指定 `protocol` 最终流向这里配置的端口。
- `name`： `Service` 的名字，它的用处主要在 dns 方面。
- `type`： 是前面提到的类型，如果没指定默认是 `ClusterIP`。



## 解决网络问题

redis 的pod 一直是Pending/ContainerCreating, t同时coreDNS一直是ContainerCreating

通过`kubectl describe pod redis` 查看的信息是

```shell
Failed create pod sandbox. Error syncing pod. Pod sandbox changed, it will be killed and re-created
```

从这里下载了portmap https://github.com/utf18/ansible-kubeadm/pull/3

参考这个解决

https://github.com/containernetworking/cni/issues/250

```
mkdir -p /opt/cni/bin
```

```shell
curl -L https://github.com/containernetworking/cni/releases/download/v0.3.0/cni-v0.3.0.txz -O
xz -d < cni-v0.3.0.txz | tar xvf - -C /opt/cni/bin
```

将文件中内容添加执行权限 chomod + x * 

之后重启kubelet

```shell
systemctl restart kubelet
sudo journalctl -xe | grep cni  # 查看cni的日志
```



参考：

https://github.com/kubernetes/kubeadm/issues/578

https://github.com/kubernetes/kubeadm/issues/587

### 查看pods

```
[root@node1 kubernetes]# kubectl get pods --all-namespaces
NAMESPACE     NAME                                    READY     STATUS             RESTARTS   AGE
default       redis-7c7545cbcb-lpbmf                  1/1       Running            0          2h
default       redis-master-6b464554c8-xhg9v           0/1       ImagePullBackOff   0          53m
default       redis-master1-859f5f5486-7s75j          1/1       Running            0          2h
default       redis-master2-76c4b8b684-fmj89          1/1       Running            0          2h
default       redis-master3-67bbb49cbb-9r2s5          1/1       Running            0          52m
default       redis-master3-67bbb49cbb-tdq6b          1/1       Running            0          53m
default       redis1-75cffbdd74-5n47d                 1/1       Running            0          52m
default       redis2-667f9f9fd-h8qsf                  1/1       Running            0          33m
kube-system   coredns-78fcdf6894-4nmwz                1/1       Running            0          5h
kube-system   coredns-78fcdf6894-s96lh                1/1       Running            0          5h
kube-system   etcd-node1                              1/1       Running            0          5h
kube-system   kube-apiserver-node1                    1/1       Running            0          5h
kube-system   kube-controller-manager-node1           1/1       Running            0          5h
kube-system   kube-flannel-ds-4bftq                   1/1       Running            0          5h
kube-system   kube-flannel-ds-89qld                   1/1       Running            1          5h
kube-system   kube-proxy-k9lkk                        1/1       Running            1          5h
kube-system   kube-proxy-lc2qw                        1/1       Running            0          5h
kube-system   kube-scheduler-node1                    1/1       Running            0          5h
kube-system   kubernetes-dashboard-67896bc598-gdc2z   1/1       Running            0          2h
```



```shell
[root@node1 kubernetes]# kubectl get pod --all-namespaces -o wide
NAMESPACE     NAME                                    READY     STATUS             RESTARTS   AGE       IP               NODE      NOMINATED NODE
default       redis-7c7545cbcb-lpbmf                  1/1       Running            0          2h        10.244.1.2       master    <none>
default       redis-master-6b464554c8-xhg9v           0/1       ImagePullBackOff   0          54m       10.244.1.3       master    <none>
default       redis-master1-859f5f5486-7s75j          1/1       Running            0          2h        10.244.1.4       master    <none>
default       redis-master2-76c4b8b684-fmj89          1/1       Running            0          2h        10.244.1.5       master    <none>
default       redis-master3-67bbb49cbb-9r2s5          1/1       Running            0          53m       10.244.1.7       master    <none>
default       redis-master3-67bbb49cbb-tdq6b          1/1       Running            0          53m       10.244.1.6       master    <none>
default       redis1-75cffbdd74-5n47d                 1/1       Running            0          52m       10.244.1.8       master    <none>
default       redis2-667f9f9fd-h8qsf                  1/1       Running            0          34m       10.244.1.9       master    <none>
kube-system   coredns-78fcdf6894-4nmwz                1/1       Running            0          5h        10.244.0.4       node1     <none>
kube-system   coredns-78fcdf6894-s96lh                1/1       Running            0          5h        10.244.0.2       node1     <none>
kube-system   etcd-node1                              1/1       Running            0          5h        192.168.30.131   node1     <none>
kube-system   kube-apiserver-node1                    1/1       Running            0          5h        192.168.30.131   node1     <none>
kube-system   kube-controller-manager-node1           1/1       Running            0          5h        192.168.30.131   node1     <none>
kube-system   kube-flannel-ds-4bftq                   1/1       Running            0          5h        192.168.30.131   node1     <none>
kube-system   kube-flannel-ds-89qld                   1/1       Running            1          5h        172.17.0.1       master    <none>
kube-system   kube-proxy-k9lkk                        1/1       Running            1          5h        172.17.0.1       master    <none>
kube-system   kube-proxy-lc2qw                        1/1       Running            0          5h        192.168.30.131   node1     <none>
kube-system   kube-scheduler-node1                    1/1       Running            0          5h        192.168.30.131   node1     <none>
kube-system   kubernetes-dashboard-67896bc598-gdc2z   1/1       Running            0          2h        10.244.0.3       node1     <none>

```

pod 状态：https://kubernetes.feisky.xyz/troubleshooting/pod

[flannel下载](https://github.com/coreos/flannel)https://github.com/coreos/flannel/releases

将下载的flannel文件放到/opt/cni/bin 

```
mv flanneld flannel
```

### 其他CNI

calico https://docs.projectcalico.org/v3.9/getting-started/kubernetes/

k8s官网：https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

阳明的博客：使用 kubeadm 搭建 v1.15.3 版本 Kubernetes 集群

https://www.qikqiak.com/post/use-kubeadm-install-kubernetes-1.15.3/