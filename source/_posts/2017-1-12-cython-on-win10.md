---
layout: post
title: 在WIN10下使用Cython
categories: Cython  Python
author: alenym@qq.com
---
## 目录 ##

- [Cython](#hh0) 
- [软件安装](#hh1) 
- [跟着Cython的tutorial走](#hh2) 
- [与python代码进行测试比较](#hh3) 


## <a name="hh0"></a> Cython ##

&nbsp;
&nbsp;
&nbsp;
&nbsp;
`Cython`不是`CPython`的简称，而是一种提升`Python`代码执行效率的解决方案。
据说一般达到30x。一会我们来看看是不是真的。这个技术对老鸟来说已经是好多
年前的了。但是很多情况下python用户真的用不上，所以不知道也无妨。

## <a name="hh1"></a> 软件安装 ##

&nbsp;
&nbsp;
&nbsp;
&nbsp;
我已经迁移到`python3`了，使用的是`Anaconda`。感谢`Anaconda`让我们的生活变
的更加美好。以下软件安装的顺序不要错。

1.  安装Visual C++ Build Tools 2015
2.  安装Anaconda3

## <a name="hh2"></a> 跟着Cython的tutorial走 ##


&nbsp;
&nbsp;
&nbsp;
&nbsp;
先创建一个helloworld.pyx文件。内容如下。

```python
# helloworld.pyx
print("hello cython!")

def fib(n):
    if n == 0 or n == 1:
        return 1
    else:
        return fib(n - 2) + fib(n - 1)
```


&nbsp;&nbsp;&nbsp;&nbsp;
再创建一个setup.py文件。内容如下

```python
#setup.py
from distutils.core import setup
from Cython.Build import cythonize

setup(
    ext_modules = cythonize("helloworld.pyx")
)
```


&nbsp;&nbsp;&nbsp;&nbsp;
然后在命令行输入

	D:\tmp\oo>python setup.py build_ext --inplace
	running build_ext
	building 'helloworld' extension
	C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\BIN\x86_amd64\cl.exe /c /nologo /Ox /W3 /GL /DNDEBUG /MD -IC:\Anaconda3\include -IC:\Anaconda3\include "-IC:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\INCLUDE" "-IC:\Program Files (x86)\Windows Kits\10\include\10.0.10240.0\ucrt" "-IC:\Program Files (x86)\Windows Kits\10\include\10.0.10240.0\shared" "-IC:\Program Files (x86)\Windows Kits\10\include\10.0.10240.0\um" "-IC:\Program Files (x86)\Windows Kits\10\include\10.0.10240.0\winrt" /Tchelloworld.c /Fobuild\temp.win-amd64-3.5\Release\helloworld.obj
	helloworld.c
	C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\BIN\x86_amd64\link.exe /nologo /INCREMENTAL:NO /LTCG /DLL /MANIFEST:EMBED,ID=2 /MANIFESTUAC:NO /LIBPATH:C:\Anaconda3\libs /LIBPATH:C:\Anaconda3\PCbuild\amd64 "/LIBPATH:C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\LIB\amd64" "/LIBPATH:C:\Program Files (x86)\Windows Kits\10\lib\10.0.10240.0\ucrt\x64" "/LIBPATH:C:\Program Files (x86)\Windows Kits\10\lib\10.0.10240.0\um\x64" /EXPORT:PyInit_helloworld build\temp.win-amd64-3.5\Release\helloworld.obj /OUT:D:\tmp\oo\helloworld.cp35-win_amd64.pyd /IMPLIB:build\temp.win-amd64-3.5\Release\helloworld.cp35-win_amd64.lib
	helloworld.obj : warning LNK4197: export 'PyInit_helloworld' specified multiple times; using first specification
	   Creating library build\temp.win-amd64-3.5\Release\helloworld.cp35-win_amd64.lib and object build\temp.win-amd64-3.5\Release\helloworld.cp35-win_amd64.exp
	Generating code
	Finished generating code
	

&nbsp;&nbsp;&nbsp;&nbsp;
(WIN10下的命令窗口终于可以使用ctrl-c和ctrl-v了。泪奔。)
可以发现多了一个`.pyd`文件。然后测试一下。

	D:\tmp\oo>python
	Python 3.5.2 |Anaconda custom (64-bit)| (default, Jul  5 2016, 11:41:13) [MSC v.1900 64 bit (AMD64)] on win32
	Type "help", "copyright", "credits" or "license" for more information.
	>>> import helloworld as h
	hello cython!
	>>>h.fib(3)
	3



&nbsp;&nbsp;&nbsp;&nbsp;
真是不错啊。可是如果你换一个目录比如不在当前包含`.pyd`的目录下，
再想导入helloworld则是不行的。怎么回事，我们不是已经setup了么。
原因在于`--inplace`这个参数，它表示只生成动态链接库。

## <a name="hh3"></a> 与python代码进行测试比较 ##

&nbsp;&nbsp;&nbsp;&nbsp;
我们还在那个目录下创建一个`test.py`文件。
```python
#test.py
def fib(n):
    if n == 0 or n == 1:
        return 1
    else:
        return fib(n - 2) + fib(n - 1)


def test_fib():
    import timeit
    n = 1000
    t = timeit.timeit("fib(25)", number=n, setup="from __main__ import fib")
    time = t / n
    print("python fib : {:.8f}s".format(time))

def test_fib_cython():
    import timeit
    n = 1000
    t = timeit.timeit("h.fib(25)", number=n, setup="import helloworld as h")
    time = t / n
    print("cython fib : {:.8f}s".format(time))

if __name__ == "__main__":
    test_fib()
    test_fib_cython()
```

&nbsp;&nbsp;&nbsp;&nbsp;
然后运行

	D:\tmp\oo>python test.py
	python fib : 0.05887972s
	hello cython!
	cython fib : 0.01739922s
	
 
&nbsp;&nbsp;&nbsp;&nbsp;
怎么回事，说好的30x呢，还轻轻松松？别着急，我们把之前的`helloworld.pyx`
修改一下。


```python
#helloworld.pyx
cpdef int fib(int n) :
    if n == 0 or n == 1 :
        return 1
    else :
        return fib(n - 2) + fib(n - 1)
```

&nbsp;&nbsp;&nbsp;&nbsp;
再运行一下瞅瞅。

	D:\tmp\oo>python test.py
	python fib : 0.05774631s
	hello cython!
	cython fib : 0.00059495s


&nbsp;&nbsp;&nbsp;&nbsp;
真是不错哦，诚不我欺，100x。
