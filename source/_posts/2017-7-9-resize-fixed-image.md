---
title: "How to resize VirtualBox fixed image size and keep contents unchanged ?"
categories: image resize virutalbox
author: alenym@qq.com
---
## 目录 ##

- [问题](#hh0) 
- [用GParted实现](#hh1) 
- [解决最后的小问题](#hh2) 


## <a name="hh0"></a> 问题 ##

如何更改镜像文件的大小呢，尤其是如何把一个固定大小的镜像变大，并且之前的内容完全不改变。
我尝试了一些方法，比如下面的几个步骤。1.查看信息，2.克隆新的vdi，3.调整大小，4.再查看信息。

> VBoxManage showhdinfo mydisk.vdi  
> VBoxManage clonehd mydisk.vdi mydiskClone.vdi  
> VBoxManage modifyhd mydiskClone.vdi --resize 61440  
> VBoxManage showhdinfo mydiskClone.vdi

这个方法的确是调整了大小，不过镜像文件变成了`dynamic size`而不是`fixed size`。这还好了，
最麻烦的是，当使用新的vdi的时候，发现自己的用户已经无法登陆，只能使用root用户登陆了。
这是无法接受的。

## <a name="hh1"></a> 用GParted实现 ##

幸运的是有人给出了详细的方法。
> ![resize-method](/images/20170710-1.jpg)

我来解释一下，其中最核心的就是

	dd if=/dev/sda of=/dev/sdb

执行完成这个语句之后，不要进行分区等任何操作。
（虽然看到新增加的磁盘处于未分配的状态。）直接单独挂载这个磁盘启动。
果然可以登陆，一切照旧。但是只是这样并没有完成磁盘空间变大。只是实现了内容的复制。
要想扩大，就需要使用GParted进行resize了。重新使用GParted Live CD进入新磁盘的分区图形界面，
可以发现新磁盘的某些空间已经进行分区，但是还有部分空间没有进行分区。
在我这里是这样显示的
<pre>
 ------------------------------------------------------
 |     sda            |  swap  |     unallocated      |   
 ------------------------------------------------------
</pre>

1. 首先删掉swap交换分区。这样/dev/sda分区紧接着就是未分配的空间了。
2. 接着resize sda分区。留几百兆做swap交换分区。
3. 最后创建一个交换分区。

最后重启。应该会发现无法登陆，出现这样一个提示
`a start job is running for dev-disk-by…`。耐心等待一下，发现还是可以正常登陆的。
而且磁盘的空间变大了。一切似乎不错。

## <a name="hh2"></a> 解决最后的小问题 ##

重启一下看看，发现还是有`a start job is running for dev-disk-by…`这个提示，
需要等待一两分钟，真是糟糕。别担心，这是因为重新创建了swap交换分区的缘故。有人已经给出了解决办法。

> To avoid the issue, in /etc/fstab you can either
> Replace the swap UUID with the new one (run sudo blkid to find it) after the primary partition resizing.

![reset-swap-uuid](/images/20170710-2.jpg)


重启，问题解决了。
