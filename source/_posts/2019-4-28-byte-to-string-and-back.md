---
title: Java语言中bytes convert to string and back not equal
date: 2019-4-28
author: alenym@qq.com
tags: 
  - java 
  - golang
---

## 问题 ##

用google搜索关键词"java bytes to string and back not equal"，第一个就是我说的这个问题。
什么意思呢？就是在java中，bytes转化为string之后，再转换回bytes的时候，发现不相同了。
**但是`Go`语言就没有这个问题哦**。

<!-- more  -->

运行如下java代码

```java
byte[] a = new byte[]{(byte) 0xc0, (byte) 0xa8, (byte) 0x00, (byte) 0x01, (byte) 0x04, (byte) 0x38};
System.out.println(ByteBufUtil.hexDump(a));
String s = new String(a);
System.out.println(ByteBufUtil.hexDump(s.getBytes()));
```

输出的结果如下：


```
c0a800010438
efbfbdefbfbd00010438
```

## 分析 ## 

bytes转化为string类型，本质上要选择一种编码。那么选择的是什么呢？
我们看看`new String()`执行的代码。通过跟踪，可以看到，使用了默认的编码。
csn为`UTF-8`。

```
static char[] decode(byte[] ba, int off, int len) {
    String csn = Charset.defaultCharset().name();
    try {
        // use charset name decode() variant which provides caching.
        return decode(csn, ba, off, len);
    } catch (UnsupportedEncodingException x) {
        warnUnsupportedCharset(csn);
    }
    try {
        return decode("ISO-8859-1", ba, off, len);
    } catch (UnsupportedEncodingException x) {
        // If this code is hit during VM initialization, MessageUtils is
        // the only way we will be able to get any kind of error message.
        MessageUtils.err("ISO-8859-1 charset not available: "
                         + x.toString());
        // If we can not find ISO-8859-1 (a required encoding) then things
        // are seriously wrong with the installation.
        System.exit(1);
        return null;
    }
}
```

因为通常java编译的时候的默认编码是`UTF-8`。
那么如何保证转化为字符串还能够转换回来呢？

一种方法是使用`ISO-8859-1`。例如，

```java 
byte[] a = new byte[]{(byte) 0xC0, (byte) 0xa8, (byte) 0x00, (byte) 0x01, (byte) 0x04, (byte) 0x38};
System.out.println(ByteBufUtil.hexDump(a));
String s = new String(a, Charset.forName("ISO-8859-1"));
System.out.println(ByteBufUtil.hexDump(s.getBytes(Charset.forName("ISO-8859-1"))));
```
结果是相等的。
```
c0a800010438
c0a800010438
```

## Go语言没有这个问题 ##

Go语言则对这个问题解决的非常好。

```go
a := []byte{0xc0, 0xa8, 0x00, 0x01, 0x04, 0x38}
fmt.Println(a)
s := string(a)
b := []byte(s)
fmt.Println(b)
```
运行结果是相等的。

```
[192 168 0 1 4 56]
[192 168 0 1 4 56]
```