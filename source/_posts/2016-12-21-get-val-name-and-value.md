---
layout: post
title: R和Python里得到传入参数的变量名
categories: R  Python
author: alenym@qq.com
---
## 目录 ##

- [问题](#hh0) 
- [python可以做到](#hh1) 
- [R也可以](#hh2) 


## <a name="hh0"></a> 问题 ##

&nbsp;&nbsp;&nbsp;&nbsp;同事写R程序的时候，问我能不能获取一个变量的`name`，
我说这个好办啊，在R里可以这样写，用`quote()`

	> a <- 1
	> quote(a)
	a

&nbsp;&nbsp;&nbsp;&nbsp;不过我把问题想简单了，他实际需要的是要获得传入
参数的`name`。例如定义一个函数`foo(c)`, 给它传入参数`a`，我能够在函数
内部知道传入参数的名字`a`。



&nbsp;&nbsp;&nbsp;&nbsp;我说可以增加一个参数嘛。把参数的名字直接传入。

	> foo(a,"a")

&nbsp;&nbsp;&nbsp;&nbsp;但是我立刻意识到，这里存在重复，而写代码是提倡
`do not repeat yourself`的。而且对R这种可以随意获取环境变量的高级语言。
肯定有办法做到。

## <a name="hh1"></a> python可以做到 ##

&nbsp;&nbsp;&nbsp;&nbsp;但是我还是先看看Python吧，毕竟最近用Python
多一些。Google关键字`python print variable name and value`,立刻可以获得
答案。这段代码的思想也很直白，就是对输入的obj在环境变量（名称,对象）键值对
中查找，返回名称。

	def namestr(obj, namespace=globals()):
	    return [name for name in namespace if namespace[name] is obj]

&nbsp;&nbsp;&nbsp;&nbsp;这样可以这样使用

	>>> a = 1
	>>> namestr(a)
	['a']


## <a name="hh2"></a> R也可以 ##

&nbsp;&nbsp;&nbsp;&nbsp;那么R肯定也有办法做到。Google关键字
`r print variable name and value`
	
	myfunc <- function(v1) {
	  deparse(substitute(v1))
	}
	
	myfunc(foo)
	[1] "foo"

&nbsp;&nbsp;&nbsp;&nbsp;真是很不错啊。把结果告诉了同事，他也很高兴。
但是`substitute()`和`deparse()`究竟是啥意思呢？在R里输入`?substitute`，可以
看到解释。

> substitute returns the parse tree for
> the (unevaluated) expression expr, substituting any variables bound in env.

&nbsp;&nbsp;&nbsp;&nbsp;够晦涩难懂的吧。不过仔细思考一下，也大概明白了。
在R里，从语法角度来说，所有都是`expr`，（这跟其他语言都是`statement`不同）
在R的函数里，可以对传入的未进行求值的`expr`进行操作。这点非常有趣。
而`deparse()`，比较好理解了至少在我看来，与`as.character()`的作用是一样的。



