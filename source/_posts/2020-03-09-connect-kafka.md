---
title:  docker容器内访问mac主机的kafka
date: 2020-03-09
author: alenym@qq.com
tags: 
  - kafka
  - container
  - docker
---

## 从容器内访问主机的kafka ##

我最近遇到这样一个需求，需要从容器内的ClickHouse访问安装在mac主机的kafka。这个问题似乎很简单，
因为在windows上，虚拟机可以和host组成一个局域网，因此kafka只要绑定此网段的ip地址即可。
但是在我的mac主机下，这个方案行不通。

<!-- more -->

有几个原因，

1. ClickHouse无法直接安装在mac上，需要编译（当然8G内存也可以编译，但是ninja需要限制job数量，要花很长时间）。
2. 我的mac内存只有8G，使用vbox根本不可能，只能使用docker。
3. 有现成的镜像，直接可以启动。并且host上可以直接连接ClickHouse。

难点就在于容器和host根本不在一个网段。

## 解决步骤 ## 

1. 修改主机上的kafka的相关配置如下

```text
listeners=PLAINTEXT://0.0.0.0:9092

advertised.listeners=PLAINTEXT://host.docker.internal:9092
```

2. `/etc/hosts`文件添加

```text
127.0.0.1       host.docker.internal
```

3. 在容器内，访问`host.docker.internal:9092`


## 原理 ##  

docker desktop for mac会默认提供一个域名`host.docker.internal`给容器内
的应用访问主机的服务。所以，如果主机上启动一个rest服务`localhost:8080`，则容器内可以通过
`host.docker.internal:8080`直接访问。

但是如果kafka只是配置为
```
listeners=PLAINTEXT://localhost:9092
```
想直接访问kafka的broker则是不行的。我们会发现，在容器内，`telnet host.docker.internal 9092`是通的。这是为什么呢？

想要连接kafka的broker会进行基本的两步交互。

1. client访问broker的地址"A"，然后broker会发送回去一个`advertised`地址"B"
2. client接收到地址"B"，然后尝试访问"B"

如果不设置`advertised.listeners`，那么默认等于`listeners`的值。

所以对于这样的设置
`B=A=PLAINTEXT://localhost:9092`。容器内尝试访问"host.docker.internal:9092"，则会这样子，

1. 容器内访问host.docker.internal:9092，接收到地址B=PLAINTEXT://localhost:9092
2. 然后访问地址localhost:9092，失败。

而如果在主机上访问则显然是成功的。

而我们的解决方法配置是这样的
`A=PLAINTEXT://localhost:9092, B=PLAINTEXT://host.docker.internal:9092`

所以如果容器内访问的过程就是，

1. 容器内访问host.docker.internal:9092，接收到地址B=PLAINTEXT://host.docker.internal:9092
2. 然后访问host.docker.internal:9092，成功。

而主机上的过程是，

1. 主机上访问localhost:9092,接收到地址B=PLAINTEXT://host.docker.internal:9092
2. 然后访问host.docker.internal:9092，根据/etc/hosts的域名解析为127.0.0.1:9092，成功。



## 测试 ##

我这里用`kafkacat`测试，实际上容器内的应用可以使用其他kafka客户端。

连接broker,并显示metadata
```shell
root@bb6b85562200:/# kafkacat -b host.docker.internal:9092 -L
Metadata for all topics (from broker 0: host.docker.internal:9092/0):
 1 brokers:
  broker 0 at host.docker.internal:9092
 8 topics:
  topic "test-topic" with 1 partitions:
    partition 0, leader 0, replicas: 0, isrs: 0
  topic "flink-test" with 1 partitions:
    partition 0, leader 0, replicas: 0, isrs: 0
  topic "__consumer_offsets" with 50 partitions:
    partition 0, leader 0, replicas: 0, isrs: 0
    partition 10, leader 0, replicas: 0, isrs: 0
...
...
```

显示消息
```shell
^Croot@bb6b85562200:/# kafkacat -b host.docker.internal:9092 -C -t flink-test -o beginning
{seqNo: 1, eventTs: 1583739799986, id: even偶数, value: 4.57}
% Reached end of topic flink-test [0] at offset 1
```
