# 搭建 Kubernetes 集群 - 本地快速搭建

在单机版本中使用kind 和Mindkube进行搭建

KIND（Kubernetes in Docker）是为了能提供更加简单，高效的方式来启动 K8S 集群，目前主要用于比如 `Kubernetes` 自身的 CI 环境中。

## 安装Kind (k8s in Docker)

- 可以直接在项目的 [Release 页面](https://github.com/kubernetes-sigs/kind/releases) 下载已经编译好的二进制文件。
- KIND 已经发布了 v0.7.0 版本，如果你想使用新版本，建议参考 [使用 Kind 在离线环境创建 K8S 集群](https://zhuanlan.zhihu.com/p/105173589) ，这篇文章使用了最新版本的 KIND
- [kind官方文档](https://kind.sigs.k8s.io/)

使用二进制文件

```shell
mv kind-linux-amd64 kind
chmod +x 
mv kind /usr/local/bin/kind
```

## 搭建单节点集群

- 以上命令中， `--name` 是可选参数，如不指定，默认创建出来的集群名字为 `kind`。
- 执行下面的命令会首先下载镜像docker.io/kindest/node 1.2G

```she
# kind create cluster --name kind-hzx
Creating cluster "kind-hzx" ...
⢎⡠ Ensuring node image (kindest/node:v1.17.0) 🖼 
✓ Preparing nodes 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
Set kubectl context to "kind-kind-hzx"
You can now use your cluster with:

kubectl cluster-info --context kind-kind-hzx


```

### 启动kind

- 执行如下命令的时候回需要先安装kubectl

```shell
[root@localhost ~]# kubectl cluster-info --context kind-kind-hzx
Kubernetes master is running at https://127.0.0.1:32768
KubeDNS is running at https://127.0.0.1:32768/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

```

### 查看当前节点

```shell
[root@localhost ~]# kubectl get nodes
NAME                     STATUS   ROLES    AGE    VERSION
kind-hzx-control-plane   Ready    master   110m   v1.17.0

```

单节点的 Kubernetes 已经搭建成功

## 安装kubectl

官方文档提供了 `macOS`, `Linux`, `Windows` 等操作系统上的安装方式，且描述很详细，这里不过多赘述，[文档地址](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl)

```shell
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl

```

```shell
chmod +x kubectl
mv kubectl /usr/local/bin/
kubectl version --client
```

### 查看kubectl版本

```json
 kubectl version
Client Version: version.Info{Major:"1", Minor:"17", GitVersion:"v1.17.4", GitCommit:"8d8aa39598534325ad77120c120a22b3a990b5ea", GitTreeState:"clean", BuildDate:"2020-03-12T21:03:42Z", GoVersion:"go1.13.8", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"17", GitVersion:"v1.17.0", GitCommit:"70132b0f130acc0bed193d9ba59dd186f0e634cf", GitTreeState:"clean", BuildDate:"2020-01-14T00:09:19Z", GoVersion:"go1.13.4", Compiler:"gc", Platform:"linux/amd64"}

```

### 集群配置文件

```
$HOME/.kube/config
```



## 安装 Minikube

Minikube 的 [Release 页面](https://github.com/kubernetes/minikube/releases)

### 安装准备

推荐无论你在以上哪种操作系统中使用 Minikube 都选择用 `Virtualbox` 作为虚拟化管理程序，1. Virtualbox 无论操作体验还是安装都比较简单 2. Minikube 对其支持更完备，并且也已经经过大量用户测试，相关问题均已基本修复。

*如果你是在 Linux 系统上面，其实还有一个选择，便是将 Minikube 的 `--vm-driver` 参数设置为 `none` ，并且在本机已经正确安装 Docker。 这种方式是无需虚拟化支持的*

在minikube1.8.2版本中s使用`--driver=none`

```
[root@localhost ~]# minikube start
! minikube v1.8.2 on Centos 7.6.1810
* Automatically selected the docker driver
* The "docker" driver should not be used with root privileges.
* If you are running minikube within a VM, consider using --driver=none:
*   https://minikube.sigs.k8s.io/docs/reference/drivers/none/

```



### 创建第一个 K8S 集群

使用 Minikube 创建集群，只要简单的执行 `minikube start` 即可

```shell
minikube start --driver=none
```

网络原因

```
[root@localhost ~]# minikube start --driver=none
* minikube v1.8.2 on Centos 7.6.1810
* Using the none driver based on user configuration
* Running on localhost (CPUs=1, Memory=972MB, Disk=17394MB) ...
* OS release is CentOS Linux 7 (Core)
! Node may be unable to resolve external DNS records
! VM is unable to access k8s.gcr.io, you may need to configure a proxy or set --image-repository
* Preparing Kubernetes v1.17.3 on Docker 1.13.1 ...
* 
X Failed to update cluster
* Error: [DOWNLOAD_IO_TIMEOUT] downloading binaries: downloading kubelet: download failed: https://storage.googleapis.com/kubernetes-release/release/v1.17.3/bin/linux/amd64/kubelet?checksum=file:https://storage.googleapis.com/kubernetes-release/release/v1.17.3/bin/linux/amd64/kubelet.sha256: invalid checksum: Error downloading checksum file: Get https://storage.googleapis.com/kubernetes-release/release/v1.17.3/bin/linux/amd64/kubelet.sha256: net/http: TLS handshake timeout
* Suggestion: A firewall is likely blocking minikube from reaching the internet. You may need to configure minikube to use a proxy.
* Documentation: https://minikube.sigs.k8s.io/docs/reference/networking/proxy/
* Related issues:
  - https://github.com/kubernetes/minikube/issues/3846

```

配置阿里的镜像

[解决参考](https://github.com/kubernetes/minikube/issues/5860)

```
minikube start --driver=none  --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
```



### 查看集群状态

```
minikube status
```

### 验证集群配置

```
 kubectl cluster-info
```
