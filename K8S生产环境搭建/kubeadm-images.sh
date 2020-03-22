#!/bin/bash

images=(
kube-apiserver-amd64:v1.11.3
kube-controller-manager-amd64:v1.11.3
kube-scheduler-amd64:v1.11.3
kube-proxy-amd64:v1.11.3
pause:3.1
etcd-amd64:3.2.18
coredns:1.1.3
)

for imageName in ${images[@]} ; do
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName
    docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName k8s.gcr.io/$imageName
done

