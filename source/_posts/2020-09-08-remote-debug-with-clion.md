---
title:  基于CLion和gdbserver实现远程调试c程序
date: 2020-09-08
author: alenym@qq.com
tags: 
  - debug
  - CLion
  - gdb
  - remote
---

## 远程调试c程序 ##

最近基于[tsar](https://github.com/alibaba/tsar)（阿里开源的一个基于c语言的监控程序）做二次开发，
因为以前从来没有在工作中写过c，所以这个简单的工作花了两周时间，期间用gdb进行调试，用valgrind检查内存泄漏。
但是最让我不舒服的就是gdb调试了，虽然gdb很给力，但是毕竟由奢入俭难，之前写Java，Python，Go都是可以用IDE进行
debug的。有图形化界面还是效率高很多，而对于新手，能够方便的debug源码就可以快速的理解项目。

那么怎么办呢？

<!-- more  -->


## CLion ##

我一直以为CLion可以很好的理解cmake项目，但是对于大量的基于makefile编译的项目，则不能很好的解析，所以也无法利用CLion
进行代码调试。

但是并不是这样，虽然CLion无法理解代码中各种符号之间的依赖关系，但是调试只要有debug info和源码就可以进行图形化调试。

参考CLion远程开发的[Remote GDB Server](https://www.jetbrains.com/help/clion/remote-gdb-server.html)，很简单就实现了。

## 远程调试tsar ##


1. mac下安装了CLion，linux下编译tsar。
在mac下，tsar项目源码路径——`/Users/ym/work/operation`
在linux下为,tsar项目源码路径——`/home/keyvalue/ym/operation`

2. 在CLion下创建一个`GDB remote debug`配置。
参数配置：

- target remote args  
  10.4.104.153:1234    # 这是gdbserver的ip:port


- path mappings 
  remote path为`/home/keyvalue/ym/operation`，local path为`/Users/ym/work/operation`

![gdb remote debug config](/images/gdb-remote-debug.png)

3. 在linux下运行命令
```
$ sudo gdbserver :1234 src/tsar --cron
Process src/tsar created; pid = 10216
Listening on port 1234
```

4. CLion下启动之前的`GDB remote debug`配置，就可以愉快的断点调试了。

![tsar remote debug](/images/tsar-remote-debug.png)