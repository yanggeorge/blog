---
title:  基于Spring Integration实现文件写入
date: 2020-08-14
author: alenym@qq.com
tags: 
  - spring
  - integration
  - write
  - file
---

## Spring Integration是什么 ##

Spring Integration是一个出现了10年的技术。随便搜索一下，就能看到历史的久远，但是实际项目中用的人很少？原因是什么呢？

<!-- more -->

难！很难！

因为Spring Integration已经是一套DSL了。所以学习它就是学习一种新的语言，一种新的编程范式。

## 写入文件 ##

就拿最简单的一个使用，如何写入一个文件，Google了几遍只能找到Spring的官方文档中的例子。如下

```java
@SpringBootApplication
@IntegrationComponentScan
public class FileWritingJavaApplication {

    public static void main(String[] args) {
        ConfigurableApplicationContext context =
                      new SpringApplicationBuilder(FileWritingJavaApplication.class)
                              .web(false)
                              .run(args);
             MyGateway gateway = context.getBean(MyGateway.class);
             gateway.writeToFile("foo.txt", new File(tmpDir.getRoot(), "fileWritingFlow"), "foo");
    }

    @Bean
    @ServiceActivator(inputChannel = "writeToFileChannel")
    public MessageHandler fileWritingMessageHandler() {
         Expression directoryExpression = new SpelExpressionParser().parseExpression("headers.directory");
         FileWritingMessageHandler handler = new FileWritingMessageHandler(directoryExpression);
         handler.setFileExistsMode(FileExistsMode.APPEND);
         return handler;
    }

    @MessagingGateway(defaultRequestChannel = "writeToFileChannel")
    public interface MyGateway {

        void writeToFile(@Header(FileHeaders.FILENAME) String fileName,
                       @Header(FileHeaders.FILENAME) File directory, String data);

    }
}
```

可是一运行发现根本跑不起来，而且问题不止一处。

## 完整的例子 ## 

我先给出修改后的可以正常运行的代码吧。可以和上面的比较一下，差别有好几处。

```java
@Configuration
@IntegrationComponentScan
public class FileWriteConfig {

    @Bean
    public MessageChannel writeToFileChannel() {
        DirectChannel directChannel = new DirectChannel();
        directChannel.subscribe(fileWritingMessageHandler());
        return directChannel;
    }

    @Bean
    public MessageHandler fileWritingMessageHandler() {
        Expression directoryExpression = new SpelExpressionParser().parseExpression("headers.directory");
        FileWritingMessageHandler handler = new FileWritingMessageHandler(directoryExpression);
        handler.setFileExistsMode(FileExistsMode.REPLACE);
        //https://stackoverflow.com/questions/29274479/spring-integration-no-output-channel-or-replychannel-header-available
        handler.setExpectReply(false);
        return handler;
    }

    @MessagingGateway(defaultRequestChannel = "writeToFileChannel")
    public interface FileWriteGateway {

        void writeToFile(@Header(FileHeaders.FILENAME) String fileName,
                         @Header("directory") File directory,
                         String data);

    }

}
```

然后写一个测试。

```java
@RunWith(SpringRunner.class)
@SpringBootTest(classes = Application.class)
@WebAppConfiguration
public class FileWriteGatewayTest {

    @SuppressWarnings("SpringJavaInjectionPointsAutowiringInspection")
    @Autowired
    FileWriteConfig.FileWriteGateway gateway;


    @Test
    public void test(){
        gateway.writeToFile("foo.txt", new File("/Users/ym/tmp/"), "fff");
    }

}
```

用法非常简单。但是配置却花了好长时间。但是只有通过使用才能慢慢理解这个框架。

写代码是不是像搭积木，像玩`magspace`。