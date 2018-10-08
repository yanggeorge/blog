---
title: "How to call java code in Grails 3.2.6"
tags: 
  - java 
  - grails 
  - gradle
  
author: alenym@qq.com
date: 2017-3-6
---
 

## <a name="hh0"></a> 解决方法 ##



我的`Grails`的环境是
	
	grails -v
	| Grails Version: 3.2.6
	| Groovy Version: 2.4.7
	| JVM Version: 1.8.0_71

<!-- more -->

grails 3.2.6是用gradle进行构建的。所以如果要添加java类，
就需要修改`build.gradle`。

## <a name="hh1"></a> 第一步 ##






创建`src/main/java`目录。对于`com.yanggeorge.XMLtest`类，
则要创建`src/main/java/com/yanggeorge/`目录，并把XMLtest.java放在该
路径下。

## <a name="hh2"></a> 第二步 ##






在`build.gradle`文件中添加如下代码

```groovy
apply plugin: "java"

task compileOne (type: JavaCompile) {
    source = sourceSets.main.java.srcDirs
    include 'com/yanggeorge/XMLtest.java'
    classpath = sourceSets.main.compileClasspath
    destinationDir = sourceSets.main.output.classesDir
}

compileOne.options.compilerArgs = ["-sourcepath", "$projectDir/src/main/java"]
```

## <a name="hh3"></a> 第三步 ##

编译XMLtest.java。可以用`grails compile`进行编译。

	D:\work\grails>grails compile
	:compileJava UP-TO-DATE
	:compileGroovy UP-TO-DATE
	:buildProperties
	:processResources UP-TO-DATE
	:classes UP-TO-DATE
	
	BUILD SUCCESSFUL
	
	Total time: 23.638 secs
	D:\work\grails>

## <a name="hh4"></a> 第四步 ##






修改`grails-app/conf/spring/resources.groovy`

```groovy
import com.yanggeorge.XMLtest

beans = {
    myXMLtest(XMLtest)
}
```

## <a name="hh5"></a> 第五步 ##





已经可以使用`myXMLtest`了，例如创建一个service，`grails-app/services/rss/RssService.groovy`
第６行就是依赖注入的bean。
```groovy
import grails.transaction.Transactional

@Transactional
class RssService {

    def myXMLtest

    def serviceMethod(String url, String keyword) {
        def items = myXMLtest.getAllItems(url)

    }

}
```

