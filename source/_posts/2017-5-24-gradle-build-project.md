---
title: "Gradle脚本实现web开发框架的一键构建"
tags: 
  - java 
  - gradle 
  - build 
  
author: alenym@qq.com
date: 2017-5-24
---

## <a name="hh0"></a> 问题 ##


Java世界里构建项目用什么工具呢，ant，maven和gradle。maven非常流行，
原因无非是maven仓库和项目架构的约定。但是ant构建过程更加容易理解，
因为ant展示了所有的操作。gradle拥有基于groovy语言的DSL语言且继承了
maven仓库的思想所以笔者认为未来是属于gradle的。

<!-- more -->

特别是最近在搭建springmvc-jpa-mysql开发框架的时候，发现怎么也找不到一个
archetype可以做到一键构建demo project。

## <a name="hh1"></a> 何谓一键构建 ##


何谓一键构建呢，有人用maven也可以很快搭建一个，通常可以把之前的
项目复制一份修改一下，似乎没有那么麻烦。但笔者还是觉得执行几个命令，
回车一下就构建完成，更加让人舒心。如图所示，创建一个空项目dir，然后把build.gradle
放入该路径下，执行

	gradle init
	gradle build -x test
	gradle run


就可以在浏览器里访问`http://localhost:8080/greeting?name=GoodJob`链接了。
以下是过程展示。当然了因为jar包都已经下载过了，所以似乎还比较快。
否则的话一定会联网下载jar包的。
![gradle-build-process](/images/2017-5-24-1.gif)



以下导入IDEA中后所示的文件结构。
![gradle-project-structure](/images/2017-5-24-2.jpg)

## <a name="hh2"></a> build.gradle文件内容 ##



`build.gradle`构建基于spring-boot的springmvc-jpa-mysql框架demo项目的脚本如下。
该脚本一目了然，无需赘述。

```groovy
def createFile = { String path, String content ->
    File f = file(path)
    if (f.exists()) {
        f.delete()
    }
    f.withWriter("UTF-8") { writer ->
        writer.write(content)
    }
}

task init(type: InitBuild, dependsOn : ["bak-build-file", "create-dirs", "create-files"]) {
    doLast {
        String buildGradleContent = '''
buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath("org.springframework.boot:spring-boot-gradle-plugin:1.5.2.RELEASE")
    }
}


apply plugin: 'java\'
apply plugin: 'eclipse\'
apply plugin: 'idea\'
apply plugin: 'application\'
apply plugin: 'org.springframework.boot\'

jar {
    baseName = 'spring-boot-demo\'
    version = '0.1.0\'
}

repositories {
    mavenCentral()
}

sourceCompatibility = 1.8
targetCompatibility = 1.8

dependencies {
    compile("org.springframework.boot:spring-boot-starter-web") {
        exclude module: "spring-boot-starter-tomcat"
    }
    compile("org.springframework.boot:spring-boot-starter-jetty")
    compile("org.springframework.boot:spring-boot-starter-actuator")
    compile("org.springframework.boot:spring-boot-starter-thymeleaf")
    compile("org.springframework.boot:spring-boot-starter-data-jpa")
    compile("org.springframework.boot:spring-boot-devtools")

    compile("mysql:mysql-connector-java")
    compile("org.apache.commons:commons-lang3:3.5")
    testCompile("junit:junit")
    testCompile("org.springframework.boot:spring-boot-starter-test")
}

mainClassName = "hello.Application"
'''
        createFile("build.gradle", buildGradleContent)
    }
}

task "bak-build-file"(type: Copy) {
    from "build.gradle"
    into "build.gradle.bak"
}

task "create-dirs" {
    description "create spring-boot-jpa-test project dirs."
    doLast {
        file("src/main/java/hello").mkdirs()
        file("src/main/resources/templates").mkdirs()
        file("src/main/webapp/WEB-INF/classes").mkdirs()
        file("src/test/java/hello").mkdirs()
        file("src/test/resources").mkdirs()
    }
}



task "create-files" {
    description "create spring-boot-jpa-test related files."
    doLast {
        String ApplicationContent, HelloControllerContent, UserRepositoryContent, UserContent, GreetingControllerContent
        String ApplicationTestsContent, ServletInitializerContent, HelloControllerTestContent
        String applicationPropertiesContent
        String webXmlContent, indexJspContent, greetingHtmlContent

        ApplicationContent = '''
package hello;

import java.util.Arrays;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    public CommandLineRunner commandLineRunner(ApplicationContext ctx) {
        return args -> {

            System.out.println("Let's inspect the beans provided by Spring Boot:");

            String[] beanNames = ctx.getBeanDefinitionNames();
            Arrays.sort(beanNames);
            for (String beanName : beanNames) {
                //System.out.println(beanName);
            }

        };
    }

}

		'''
        HelloControllerContent = '''
package hello;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

@RestController
public class HelloController {

    @RequestMapping("/")
    public String index() {
        return "Greetings from Spring Boot!";
    }

}
'''
        UserRepositoryContent = '''
package hello;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Created by YM on 5/16/2017.
 */
public interface UserRepository extends JpaRepository<User, Long> {

    User findByName(String name);
    User findByNameAndAge(String name, Integer age);

    @Query("from User u where u.name=:name")
    User findUser(@Param("name") String name);
}
'''
        UserContent = '''
package hello;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;

/**
 * Created by YM on 5/16/2017.
 */
@Entity
public class User {

    @Id
    @GeneratedValue
    private Long id;
    @Column(nullable = false)
    private String name;
    @Column(nullable = false)
    private Integer age;

    public User() {
    }

    public User(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public Integer getAge() {
        return age;
    }

    public String getName() {
        return name;
    }

    public Long getId() {
        return id;
    }

    public void setAge(Integer age) {
        this.age = age;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setName(String name) {
        this.name = name;
    }
}
'''
        ApplicationTestsContent = '''
import hello.Application;
import hello.User;
import hello.UserRepository;
import java.util.Date;
import org.apache.commons.lang3.time.DateUtils;
import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
import org.springframework.test.context.junit4.SpringRunner;

/**
 * Created by YM on 5/16/2017.
 */
@RunWith(SpringRunner.class)
@SpringBootTest(classes = Application.class)
public class ApplicationTests {
    @Autowired
    private UserRepository userRepository;

    @Test
    public void test() throws Exception {
        // 创建10条记录
        userRepository.save(new User("AAA", 10));
        userRepository.save(new User("BBB", 20));
        userRepository.save(new User("CCC", 30));
        userRepository.save(new User("DDD", 40));
        userRepository.save(new User("EEE", 50));
        userRepository.save(new User("FFF", 60));
        userRepository.save(new User("GGG", 70));
        userRepository.save(new User("HHH", 80));
        userRepository.save(new User("III", 90));
        userRepository.save(new User("JJJ", 100));
        // 测试findAll, 查询所有记录
        Assert.assertEquals(10, userRepository.findAll().size());
        // 测试findByName, 查询姓名为FFF的User
        Assert.assertEquals(60, userRepository.findByName("FFF").getAge().longValue());
        // 测试findUser, 查询姓名为FFF的User
        Assert.assertEquals(60, userRepository.findUser("FFF").getAge().longValue());
        // 测试findByNameAndAge, 查询姓名为FFF并且年龄为60的User
        Assert.assertEquals("FFF", userRepository.findByNameAndAge("FFF", 60).getName());
        // 测试删除姓名为AAA的User
        userRepository.delete(userRepository.findByName("AAA"));
        // 测试findAll, 查询所有记录, 验证上面的删除是否成功
        Assert.assertEquals(9, userRepository.findAll().size());
    }
}
'''
        GreetingControllerContent = '''
package hello;


import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class GreetingController {

    @RequestMapping("/greeting")
    public String greeting(@RequestParam(value = "name", required = false, defaultValue = "World") String name,
            Model model) {
        model.addAttribute("name", name);
        return "greeting";
    }

}
'''
        ServletInitializerContent = '''
package hello;

import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.support.SpringBootServletInitializer;

/**
 * Created by YM on 5/16/2017.
 */
public class ServletInitializer extends SpringBootServletInitializer {

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
        return builder.sources(hello.Application.class);
    }
}
'''
        HelloControllerTestContent = '''
package hello;

import static org.hamcrest.Matchers.equalTo;
import static org.junit.Assert.assertThat;

import java.net.URL;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.embedded.LocalServerPort;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class HelloControllerTest {

    @LocalServerPort
    private int port;

    private URL base;

    @Autowired
    private TestRestTemplate template;

    @Before
    public void setUp() throws Exception {
        this.base = new URL("http://localhost:" + port + "/");
    }

    @Test
    public void getHello() throws Exception {
        ResponseEntity<String> response = template.getForEntity(base.toString(),
                String.class);
        assertThat(response.getBody(), equalTo("Greetings from Spring Boot!"));
    }
}
'''
        createFile("src/main/java/hello/Application.java", ApplicationContent)
        createFile("src/main/java/hello/HelloController.java", HelloControllerContent)
        createFile("src/main/java/hello/UserRepository.java", UserRepositoryContent)
        createFile("src/main/java/hello/User.java", UserContent)
        createFile("src/main/java/hello/GreetingController.java", GreetingControllerContent)
        createFile("src/main/java/hello/ServletInitializer.java", ServletInitializerContent)
        createFile("src/test/java/ApplicationTests.java", ApplicationTestsContent)
        createFile("src/test/java/hello/HelloControllerTest.java", HelloControllerTestContent)

        applicationPropertiesContent = '''
spring.datasource.driverClassName=
spring.datasource.url=jdbc:mysql://localhost:3306/test
spring.datasource.username=root
spring.datasource.password=root
spring.jpa.properties.hibernate.hbm2ddl.auto=create
'''
        createFile("src/main/resources/application.properties", applicationPropertiesContent)
        println "Please modify src/main/resources/application.properties"

        webXmlContent = '''
<!DOCTYPE web-app PUBLIC
 "-//Sun Microsystems, Inc.//DTD Web Application 2.3//EN"
 "http://java.sun.com/dtd/web-app_2_3.dtd" >

<web-app>
  <display-name>Archetype Created Web Application</display-name>
</web-app>
'''
        indexJspContent = '''
<html>
<body>
<h2>Hello World!</h2>
</body>
</html>
'''
        greetingHtmlContent = '''
<!DOCTYPE HTML>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <title>Getting Started: Serving Web Content</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body>
<p th:text="'Hello, ' + ${name} + '!'" />
</body>
</html>
'''
        createFile("src/main/webapp/WEB-INF/web.xml", webXmlContent)
        createFile("src/main/webapp/index.jsp", indexJspContent)
        createFile("src/main/resources/templates/greeting.html", greetingHtmlContent)

    }
}

```
