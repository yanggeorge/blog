---
title:  在mac下跑一个Ingress的例子
date: 2020-07-06
author: alenym@qq.com
tags: 
  - k8s
  - ingress
  - docker
  - mac
---

## Ingress是什么 ##

在Kubernetes中，Ingress是一个对象，该对象允许从Kubernetes集群外部访问Kubernetes服务。 您可以 
通过创建一组规则来配置访问权限，这些规则定义了哪些入站连接可以访问哪些服务。

<!-- more  -->

这里有篇文章很好的说明了Ingress，并给出了例子 —— [Kubernetes Ingress with Nginx Example](https://matthewpalmer.net/kubernetes-app-developer/articles/kubernetes-ingress-guide-nginx-example.html)

但是要想跑一下，首先要有一个k8s集群。下面首先在mac上安装一个k8s集群。

## 在mac上安装k8s集群 ## 

我的mbp的配置是8G内存。

1. 下载`Docker.dmg`。
2. 从这里下载搭建k8s所需要的镜像——`https://github.com/gotok8s/k8s-docker-desktop-for-mac`
使用的方法就是如下，我用的docker desktop的kubernates的版本是1.19.3所以，相应的要把文件`images`中的版本号进行修改，以匹配。
```
$ git clone https://github.com/gotok8s/k8s-docker-desktop-for-mac.git
$ cd k8s-docker-desktop-for-mac
$ cat images
k8s.gcr.io/kube-proxy:v1.19.3=gotok8s/kube-proxy:v1.19.3
k8s.gcr.io/kube-controller-manager:v1.19.3=gotok8s/kube-controller-manager:v1.19.3
k8s.gcr.io/kube-scheduler:v1.19.3=gotok8s/kube-scheduler:v1.19.3
k8s.gcr.io/kube-apiserver:v1.19.3=gotok8s/kube-apiserver:v1.19.3
k8s.gcr.io/coredns:1.7.0=gotok8s/coredns:1.7.0
k8s.gcr.io/pause:3.2=gotok8s/pause:3.2
k8s.gcr.io/etcd:3.4.13-0=gotok8s/etcd:3.4.13-0
$ ./load_images.sh
```
3. 启动docker desktop，并在dashboard中修改docker使用的资源大小。我分配了5G，
交换内存设置为4G，cpu数量为3
4. 勾选`Enable Kubernetes`和`Show system containers (advanced)`，启动，然后耐心等待。

需要等待的时间比较长，因为还会下载多个镜像,如`docker/desktop-kubernetes`等等。

## 安装ingress-nginx-controller ##

我们从ingress-nginx的官网可以看到不同的安装方式，对于 Docker for Mac，一行命令搞定

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud/deploy.yaml
```

这个需要下载镜像`quay.io/kubernetes-ingress-controller/nginx-ingress-controller`，所以也需要时间。直到看到如下pods

```
ingress-nginx   ingress-nginx-admission-create-frllm       0/1     Completed   0          56m
ingress-nginx   ingress-nginx-admission-patch-gbwpd        0/1     Completed   0          56m
ingress-nginx   ingress-nginx-controller-8f7b9d799-c67xw   1/1     Running     2          56m
```

## 跑一个Ingress的例子 ##  

[Kubernetes Ingress with Nginx Example](https://matthewpalmer.net/kubernetes-app-developer/articles/kubernetes-ingress-guide-nginx-example.html)中的yaml文件需要外网才能看到。

我在此列出三个yaml文件

apple.yaml:

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: apple-app
  labels:
    app: apple
spec:
  containers:
    - name: apple-app
      image: hashicorp/http-echo
      args:
        - "-text=apple"

---

kind: Service
apiVersion: v1
metadata:
  name: apple-service
spec:
  selector:
    app: apple
  ports:
    - port: 5678 # Default port for image
```

banana.yaml :

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: banana-app
  labels:
    app: banana
spec:
  containers:
    - name: banana-app
      image: hashicorp/http-echo
      args:
        - "-text=banana"

---

kind: Service
apiVersion: v1
metadata:
  name: banana-service
spec:
  selector:
    app: banana
  ports:
    - port: 5678 # Default port for image
```

ingress.yaml:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
        - path: /apple
          backend:
            serviceName: apple-service
            servicePort: 5678
        - path: /banana
          backend:
            serviceName: banana-service
            servicePort: 5678
```

执行命令，等待一下。因为要下载一个镜像“jettech/kube-webhook-certgen”

```
$ kubectl apply -f apple.yaml
$ kubectl apply -f banana.yaml
$ kubectl create -f ingress.yaml
```

查看ingress
```
$ kubectl describe ingress -n default example-ingress
Name:             example-ingress
Namespace:        default
Address:          localhost
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /apple    apple-service:5678 (10.1.0.30:5678)
              /banana   banana-service:5678 (10.1.0.28:5678)
Annotations:  ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  CREATE  45m   nginx-ingress-controller  Ingress default/example-ingress
  Normal  UPDATE  44m   nginx-ingress-controller  Ingress default/example-ingress
  Normal  CREATE  14m   nginx-ingress-controller  Ingress default/example-ingress
```

最后测试
```

$ curl -kL http://localhost/apple
apple

$ curl -kL http://localhost/banana
banana

$ curl -kL http://localhost/notfound
default backend - 404

```
