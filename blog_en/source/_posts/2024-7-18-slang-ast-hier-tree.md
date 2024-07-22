---
title:  "如何更好的打印语法树结构"
date: 2024-7-18
author: Ming Yang
tags:
  - c++
  - AST
  - tree
katex: true 
mathjax: true
---

## 什么是语法树 ##

语法树（Syntax Tree），是一种树状数据结构，
用于表示源代码的语法结构。每个节点都表示源代码中的一种语法结构。
语法树在编译器和解释器中被广泛使用，以帮助分析和处理编程语言的源代码。

<!-- more -->

语法树可以进一步分成具体语法树（**C**oncrete **S**yntax **T**ree）和抽象语法树（**A**bstract **S**yntax **T**ree）。
编译器前端通常会根据BNF语法生成CST，然后再根据语义构建AST。

为了方便用户使用语法树，通常会支持Visitor设计模式，这样自定义的Visitor就可以针对感兴趣的节点类型进行遍历。

**所以这样就引出一个问题，节点类型那么多，如何能直观的看到这个树形结构呢？尤其对于不支持反射的C++，无法Debug查看类型**

下面是作者在基于[slang](https://sv-lang.com/)项目开发Lint规则的时候，作出的一些尝试。

slang是一个Modern C++项目，使用了很多C++17和C++20新特性。


> slang is a software library that provides various components for lexing, parsing, type checking, and elaborating SystemVerilog code. It comes with an executable tool that can compile and lint any SystemVerilog project, but it is also intended to be usable as a front end for synthesis tools, simulators, linters, code editors, and refactoring tools.
>
> slang is the fastest and most compliant SystemVerilog frontend
> 


那么在说明这个问题之前，还是要对`SystemVerilog`进行简单的介绍。然后给出序列化为json格式的语法树，最后给出作者方案作为比较。

## SystemVerilog简介 ##

`SystemVerilog` 是一种硬件描述和验证语言（HDVL），是`Verilog`硬件描述语言的扩展。它结合了硬件描述语言（HDL）和硬件验证语言（HVL）的特性，旨在提供一种更强大和灵活的工具来设计和验证数字系统。SystemVerilog 由 Accellera 标准组织开发，并已被 IEEE 标准协会标准化为 IEEE 1800。

### SystemVerilog 的主要特点

1. **综合和仿真**：支持设计综合（synthesis）和仿真（simulation），可以用来描述硬件电路并验证其行为。
2. **面向对象编程**：引入了面向对象编程（OOP）概念，如类（class）、继承（inheritance）、多态（polymorphism）等，用于更复杂的测试平台开发。
3. **高级验证功能**：包含了许多高级验证功能，如断言（assertions）、约束随机化（constraint randomization）、覆盖率（coverage）等。
4. **接口和模块化**：支持接口（interface）和模块化编程，促进设计的可重用性和模块化。
5. **并行处理**：具有并行处理能力，可以描述并行硬件行为。
6. **组合逻辑和时序逻辑**：支持组合逻辑和时序逻辑的建模。

### SystemVerilog 的基本构造

#### 模块
模块（module）是 `SystemVerilog` 的基本构造，用于定义电路的结构和行为。例如：

```verilog
module adder (
    input logic [3:0] a,
    input logic [3:0] b,
    output logic [3:0] sum
);
    assign sum = a + b;
endmodule
```

#### 接口
接口（interface）用于定义模块之间的通信信号。例如：

```verilog
interface simple_bus (
    input logic clk,
    input logic reset
);
    logic [7:0] data;
    logic valid;
endinterface
```

#### 类
类（class）用于验证环境中的面向对象编程。例如：

```verilog
class Packet;
    rand bit [7:0] addr;
    rand bit [7:0] data;

    function void display();
        $display("Address: %0h, Data: %0h", addr, data);
    endfunction
endclass
```

### SystemVerilog 的应用

1. **硬件设计**：用于描述数字电路的结构和行为，可以综合成实际的硬件电路。
2. **硬件验证**：提供了丰富的验证功能，用于验证数字设计的正确性和性能，包括功能验证和形式验证。
3. **测试平台开发**：可以用来开发复杂的测试平台，进行全面的硬件设计验证。

### SystemVerilog 的优势

1. **增强的表达能力**：相比于 Verilog，SystemVerilog 提供了更强大的语法和语义，可以更高效地描述复杂的硬件和验证环境。
2. **高效的验证方法**：引入了约束随机化、覆盖率驱动验证和断言等先进验证技术，大大提高了验证效率。
3. **面向对象编程**：支持面向对象编程，使得验证代码更具结构性和可维护性。

总的来说，`SystemVerilog` 是一种强大且灵活的硬件描述和验证语言，广泛应用于现代数字电路设计和验证领域。

## slang给出的json格式的AST ## 

slang项目提供了一个命令行工具，并提供了`--ast-json`来序列化AST为json格式。还是以这个加法器模块为例，
```verilog
module adder (
    input logic [3:0] a,
    input logic [3:0] b,
    output logic [3:0] sum
);
    assign sum = a + b;
endmodule
```
序列化的json结构如下
```json
{
  "design": {
    "name": "$root",
    "kind": "Root",
    "addr": 2199025570624,
    "members": [
      {
        "name": "",
        "kind": "CompilationUnit",
        "addr": 2199025963792
      },
      {
        "name": "adder",
        "kind": "Instance",
        "addr": 2199025964560,
        "body": {
          "name": "adder",
          "kind": "InstanceBody",
          "addr": 2199025964184,
          "members": [
            {
              "name": "a",
              "kind": "Port",
              "addr": 2199025964704,
              "type": "logic[3:0]",
              "direction": "In",
              "internalSymbol": "2199025964880 a"
            },
            {
              "name": "a",
              "kind": "Variable",
              "addr": 2199025964880,
              "type": "logic[3:0]",
              "lifetime": "Static"
            },
            {
              "name": "b",
              "kind": "Port",
              "addr": 2199025965256,
              "type": "logic[3:0]",
              "direction": "In",
              "internalSymbol": "2199025965432 b"
            },
            {
              "name": "b",
              "kind": "Variable",
              "addr": 2199025965432,
              "type": "logic[3:0]",
              "lifetime": "Static"
            },
            {
              "name": "sum",
              "kind": "Port",
              "addr": 2199025965808,
              "type": "logic[3:0]",
              "direction": "Out",
              "internalSymbol": "2199025965984 sum"
            },
            {
              "name": "sum",
              "kind": "Variable",
              "addr": 2199025965984,
              "type": "logic[3:0]",
              "lifetime": "Static"
            },
            {
              "name": "",
              "kind": "ContinuousAssign",
              "addr": 2199025966384,
              "assignment": {
                "kind": "Assignment",
                "type": "logic[3:0]",
                "left": {
                  "kind": "NamedValue",
                  "type": "logic[3:0]",
                  "symbol": "2199025965984 sum"
                },
                "right": {
                  "kind": "BinaryOp",
                  "type": "logic[3:0]",
                  "op": "Add",
                  "left": {
                    "kind": "NamedValue",
                    "type": "logic[3:0]",
                    "symbol": "2199025964880 a"
                  },
                  "right": {
                    "kind": "NamedValue",
                    "type": "logic[3:0]",
                    "symbol": "2199025965432 b"
                  }
                },
                "isNonBlocking": false
              }
            }
          ],
          "definition": "2199025746816 adder"
        },
        "connections": [
        ]
      }
    ]
  },
  "definitions": [
    {
      "name": "adder",
      "kind": "Definition",
      "addr": 2199025746816,
      "defaultNetType": "2199025567936 wire",
      "definitionKind": "Module",
      "defaultLifetime": "Static",
      "unconnectedDrive": "None"
    }
  ]
}        
```

是不是首先感到，这个json格式有点太长了，因为一个节点会有很多属性。而且通过缩进也很难看出来节点的父子关系。

## tree命令行的启发 ## 

树状结构是一个二维结构，很难展示。不过命令工具tree打印的树状结构非常清晰。

```shell
$ tree .
.
├── dir1
│    └── a.txt
└── dir2
     ├── b.txt
     └── c.txt
```
可以看到这种展示方式很好的把父子关系展示了出来，清楚的看到一个目录下所包含的文件。

这种具体的层次树`hierarchical tree`称之为目录树。

## 解决方案展示 ##

还是这个sv代码

```verilog
module adder (
    input logic [3:0] a,
    input logic [3:0] b,
    output logic [3:0] sum
);
    assign sum = a + b;
endmodule
```

### AST的优化展示 ### 
我们展示一下用目录树的方式，展现AST

![adder-ast](./images/2024-adder-ast.jpg)
可以看到每一行都是一个key-value键值对，用冒号分隔。同时加上term颜色区分。

绿色的key是节点的class类型，value部分则是节点的属性信息，以空格分隔。

这样就可以以紧凑的方式展示AST。

### CST的优化展示 ### 

`slang`并没有给出命令行的方式展现CST，但是用户可能需要直接访问CST进行一些处理，
例如：格式化sv代码。

下面是用相似的方式展现`adder`的CST数据结构。可以看出来，叶子节点的value就是该节点的原始文本。

![adder-cst](./images/2024-adder-cst.png)


## 总结 ## 

参考目录树的展示方式，结合key-value和term color给出了更加紧凑和清晰的语法树展现方式。这种方式更加方便用户基于AST和CST进行开发。 

但是这种方式的缺点也是明确的，
就是不适合作为文本方式保存。也不适合展示大的代码。当然json方式也不适合（但是都可以通过hierarchical path的约束，只展示部分语法树结构。）。


