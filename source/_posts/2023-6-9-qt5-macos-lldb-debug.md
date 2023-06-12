---
title:  "MacOS下LLDB调试Qt5程序"
date: 2023-6-9
author: alenym@qq.com
tags:
  - qt5
  - lldb
  - debug
  - macos
katex: true 
mathjax: true
---

## LLDB调试Qt5的问题 ##

MacOS下，LLDB调试Qt5应用通常会遇到无法打印QString变量的问题。

```lldb
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 1.1
    frame #0: 0x0000000100003a81 a.out`main(argc=1, argv=0x00007ff7bfefeb40) at test.cpp:10:11
   7   	   QCoreApplication a(argc, argv);
   8   	
   9   	   QString s = "Hello World";
-> 10  	   return a.exec();
   11  	}
Target 0: (a.out) stopped.
(lldb) print s
(QString) $0 = {
  d = 0x0000600000c04b70
}
```

这里无法获取变量`s`的值`Hello World`，只能看到一个地址。

<!-- more -->

同样的，使用CLion等IDE使用LLDB调试Qt5应用的时候，也无法看到值。

## LLDB Qt Formatter ##

英雄来了， [https://github.com/ayuckhulk/lldb-qt-formatters](https://github.com/ayuckhulk/lldb-qt-formatters)

> I use Xcode and LLDB to debug my Qt programs, and got tired with there being no visualisation for all the built-in types. Here I endeavour to make all of these types visible through the debugger. Works with Qt 5.x. Tested with Qt 5.9.8, 5.13.2 and XCode 11.

作者使用Xcode和LLDB开发Qt，苦于debug的时候看不到qt的内建类型的值。

怎么办呢，简单的说就是LLDB启动的时候，加载python脚本，把内建类型的显示值的计算方法替换掉。也就是LLDB可以加载这样的自定义Formatter，
对变量进行格式化输出 —— [Variable Formatting](https://lldb.llvm.org/use/variable.html)，
Python脚本非常适合实现复杂的Formatter —— [Python Scripting](https://lldb.llvm.org/use/variable.html#id7)

安装方法如下：

> git clone this repo somewhere, e.g. ~/qtlldb. Then add the following lines to your ~/.lldbinit:
> 
> command script import ~/qtlldb/QtFormatters.py </br>
> command source ~/qtlldb/QtFormatters.lldb


这样，Qt的如下内建类型的值都可以在调试的时候可视化了。

* QString
* QUrl
* QList
* QVector
* QPointer
* QSize
* QSizeF
* QPoint
* QPointF
* QRect
* QRectF
* QUuid

## 测试 ##

还用如下`test.cpp`代码测试，仅仅测试`QString`类型。

```cpp 
#include <QCoreApplication>
#include <QString>


int main(int argc, char *argv[])
{
   QCoreApplication a(argc, argv);

   QString s = "Hello World";
   return a.exec();
}
```

编译一下

```shell 
  g++ -std=c++11 test.cpp $(pkg-config --cflags --libs Qt5Core) -g
```

这里需要设置`PKG_CONFIG_PATH`一下

```zsh 
export PKG_CONFIG_PATH="/usr/local/opt/qt@5/lib/"
```

然后LLDB调试a.out。

```lldb 
$ lldb a.out
(lldb) target create "a.out"
Current executable set to '/Users/ym/tmp/lldb-qt-formatters/lldbtests/a.out' (x86_64).
(lldb) b 10
Breakpoint 1: where = a.out`main + 65 at test.cpp:10:11, address = 0x0000000100003a81
(lldb) r
Process 53042 launched: '/Users/ym/tmp/lldb-qt-formatters/lldbtests/a.out' (x86_64)
Process 53042 stopped
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 1.1
    frame #0: 0x0000000100003a81 a.out`main(argc=1, argv=0x00007ff7bfefeb40) at test.cpp:10:11
   7   	   QCoreApplication a(argc, argv);
   8   	
   9   	   QString s = "Hello World";
-> 10  	   return a.exec();
   11  	}
Target 0: (a.out) stopped.
(lldb) print s
(QString) $0 = "Hello World" {
  d = 0x0000600000c003f0
}
(lldb) 
```

这里18行"Hello World"显示出来了。

## 总结 ##

对LLDB启动进行设置之后，CLion里也可以愉快的调试了。

![lldb-debug-qt](./images/lldb-debug-qt.png)
