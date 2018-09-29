---
layout: post
title: "编译和运行Clojure分支20081217源码"
categories: java clojure jvm
author: alenym@qq.com
---
## 目录 ##

- [Clojure branch 20081217](#hh0) 
- [下载branch 20081217](#hh1) 
- [编译环境配置](#hh2) 
- [运行　](#hh3) 

## <a name="hh0"></a> Clojure branch 20081217 ##
&nbsp;
&nbsp;
&nbsp;
&nbsp;
为啥要做这件事情呢？

1. Clojure是一门jvm语言，使用了asm。
2. branch 20081217是最初的版本便于研究。

## <a name="hh1"></a> 下载branch 20081217 ##

&nbsp;
&nbsp;
&nbsp;
&nbsp;
本来直接这样一条语句很简单的事情，但是由于网络太慢。我只好
直接下载这个分支的源码zip包。

	git clone https://github.com/clojure/clojure.git
	git checkout 20081217


## <a name="hh2"></a> 编译环境配置 ##


&nbsp;
&nbsp;
&nbsp;
&nbsp;
虽然有`pom.xml`文件但是简单的导入到`IDEA`并不起作用。
还是按照官方说明来搞吧，用`ant`编译。
下载最新的ant版本1.10，并使用jdk1.8是会出错的。
想想十年前的情况。找到ant-1.7和jdk1.5进行编译才行。
以下是编译的结果，最后在根目录下生成了`clojure.jar`。

	d:\work\idea\clojure-20081217>ant
	Buildfile: build.xml
	
	clean:
	   [delete] Deleting directory d:\work\idea\clojure-20081217\classes
	
	init:
	    [mkdir] Created dir: d:\work\idea\clojure-20081217\classes
	
	compile_java:
	    [javac] Compiling 113 source files to d:\work\idea\clojure-20081217\classes
	    [javac] 注意：某些输入文件使用了未经检查或不安全的操作。
	    [javac] 注意：要了解详细信息，请使用 -Xlint:unchecked 重新编译。
	
	compile_clojure:
	     [java] Compiling clojure.core to d:\work\idea\clojure-20081217\classes
	     [java] Compiling clojure.main to d:\work\idea\clojure-20081217\classes
	     [java] Compiling clojure.set to d:\work\idea\clojure-20081217\classes
	     [java] Compiling clojure.xml to d:\work\idea\clojure-20081217\classes
	     [java] Compiling clojure.zip to d:\work\idea\clojure-20081217\classes
	     [java] Compiling clojure.inspector to d:\work\idea\clojure-20081217\classes
	
	jar:
	      [jar] Building jar: d:\work\idea\clojure-20081217\clojure.jar
	
	BUILD SUCCESSFUL
	Total time: 13 seconds

## <a name="hh3"></a> 运行　 ##


&nbsp;
&nbsp;
&nbsp;
&nbsp;
官方`readme`给出了办法来证明运行成功。执行`java -cp clojure.jar clojure.lang.Repl`
，这样就可以进入clojure的repl环境。

	d:\work\idea\clojure-20081217>java -cp clojure.jar clojure.lang.Repl
	Clojure
	user=> (def n 2)
	#'user/n
	user=> (* n 2)
	4
	user=>



&nbsp;
&nbsp;
&nbsp;
&nbsp;
如何运行一个clj文件呢？可以这样做。

- 在根路径下创建一个hello.clj文件，内容为`(print "hello world")`
- 运行命令`java -cp clojure.jar clojure.lang.Script hello.clj`


&nbsp;
&nbsp;
&nbsp;
&nbsp;
如下所示。


	d:\work\idea\clojure-20081217>java -cp clojure.jar clojure.lang.Script hello_world.clj
	hello world


&nbsp;
&nbsp;
&nbsp;
&nbsp;
成功了。

