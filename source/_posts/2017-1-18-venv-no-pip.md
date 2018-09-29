---
title: 解决python3使用system-site-packages创建虚拟环境时没有pip的问题
categories: Python3 venv
author: alenym@qq.com
---
## 目录 ##

- [python虚拟环境](#hh0) 
- [WIN下的解决办法](#hh1) 
- [Linux下的解决办法](#hh2) 
- [可能的解决办法](#hh3) 



## <a name="hh0"></a> python虚拟环境 ##





从`python3.5`开始,使用`venv`创建虚拟环境已经成为官方推荐的方案。
查看官方文档，可以看到如果想要创建一个干净的虚拟环境。方式如下

	python -m venv myenv






如果要创建一个当前环境的副本，也就是说，可以引用当前环境的所有已经
安装的包。那么需要增加`--system-site-packages`参数

	python -m venv myenv2 --system-site-packages






两种方式，我们都希望能够独立使用pip来管理包。但是第二种方式发现并没有pip
文件。

## <a name="hh1"></a> WIN下的解决办法 ##






因为我一般都是用神器`pycharm`，幸运的是`pycharm`提供了一个简单的方法。

![env-1](/images/env-1.png)

可以看到目录下是有pip的。

![env-2](/images/env-2.png)


## <a name="hh2"></a> Linux下的解决办法 ##






如果不使用`pycharm`是不是就没办法了呢。我们google一下
关键字`python system-site-packages no pip`很顺利的找到
这个链接[pyvenv doesn´t install PIP inside a new venv with --system-site-package](https://bugs.python.org/issue24875)
这个是python的bug跟踪记录。大概看看应该能明白，原来
我们遇到的这个问题，已经在`2015-08-16`就被人标记了。但是直到最近还没有解决。
但是最新的更新是几天前`last changed 2017-01-13`。呵呵看看这些大咖
都讨论些啥。






看到这句话，我笑了。这个问题的等级被标记为普通。所以一直没有解决。
而这个大咖觉得这个问题如果不解决，非但`--system-site-packages`没有用，
甚至会误导大量的初学者。

> I agree this makes --system-site-packages a useless option unless it's fixed. We just had many beginners install pyvenv's and get very confused because of this.






最后发现补丁已经提交了，而且就在几天前。但是很显然没有进入我们的安装版里。
我在我的debian虚拟机上安装了python3.6.0。测试了一下这个bug是存在的。
那么问题简单了。把源码改一下吧，根据这个[patch](https://bugs.python.org/review/24875/patch/19738/77413)
然后重新编译安装。测试一下。

	 ~/ python
	Python 3.6.0 (default, Jan 17 2017, 22:12:56) 
	[GCC 4.9.2] on linux
	Type "help", "copyright", "credits" or "license" for more information.
	>>> 
	 ~/ pip list --format=columns
	Package    Version
	---------- -------
	binarytree 1.1.1  
	pip        9.0.1  
	setuptools 28.8.0 





这是我当前的python版本和已经安装的包。其中有个`binarytree`。
现在创建一个继承全部包的虚拟环境。

	 ~/tmp/ python -m venv fenv --system-site-packages
	 ~/tmp/ cd fenv/bin
	 ~/tmp/fenv/bin/ ls
	activate      activate.fish  easy_install-3.6  pip3    python
	activate.csh  easy_install   pip               pip3.6  python3
	 ~/tmp/fenv/bin/ ./pip list --format=columns
	Package    Version
	---------- -------
	binarytree 1.1.1  
	pip        9.0.1  
	setuptools 28.8.0 





嗯成功了。

## <a name="hh3"></a> 可能的解决办法 ##






虽然第二种办法很好。但是需要修改源代码。可是服务器上的代码是不能修改的呀。
那可以尝试自己写一个venv.Builder，对其中的create方法进行覆盖，这个方法
我没有尝试。如果你尝试了，也可以发邮件告诉我结果。

