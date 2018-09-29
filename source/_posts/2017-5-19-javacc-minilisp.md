---
layout: post
title: "Write a simple parser for MiniLisp by using JavaCC"
categories: java javacc lisp
author: alenym@qq.com
---
## 目录 ##

- [MiniLisp是什么？](#hh0) 
- [JavaCC是什么？](#hh1) 
- [MiniLisp的BNF语法描述没有怎么办？](#hh2) 
- [MiniLisp的jj文件](#hh3) 
- [测试代码](#hh4) 

## <a name="hh0"></a> MiniLisp是什么？ ##

&nbsp;
&nbsp;
&nbsp;
&nbsp;
[MiniLisp](https://github.com/rui314/minilisp)是一个只用几百行代码实现的Lisp。以下是实现的
基本特性。

- integers, symbols, cons cells,
- global variables,
- lexically-scoped local variables,
- closures,
- if conditional,
- primitive functions, such as +, =, <, or list,
- user-defined functions,
- a macro system,
- and a copying garbage collector.

&nbsp;
&nbsp;
&nbsp;
&nbsp;
在笔者看来真是麻雀虽小五脏俱全啊。这是一个非常值得研究的项目。

## <a name="hh1"></a> JavaCC是什么？ ##

&nbsp;
&nbsp;
&nbsp;
&nbsp;
[JavaCC](https://javacc.org/)据说是一个非常易用好理解的`LL(k)`的Parser生成工具。
说它好理解是指它生成的Java代码要比`LR`类型的容易理解。毕竟`LL`是`Top-Down Parser`呀。
笔者以前只用过`LR(1)`类型的工具，`JavaCC`则从来没用过。

## <a name="hh2"></a> MiniLisp的BNF语法描述没有怎么办？ ##

&nbsp;
&nbsp;
&nbsp;
&nbsp;
`MiniLisp`的作者并没有使用`yacc`等工具，而是自己手写的`Top-Down Parser`。所以无法得到
`MiniLisp`的BNF描述。

&nbsp;
&nbsp;
&nbsp;
&nbsp;
没关系，既然是Lisp方言，那么先看看传统的Lisp的BNF语法是什么。这里有一个简单的BNF版本
[BNF rules of LISP](http://cui.unige.ch/isi/bnf/LISP/BNFlisp.html)

	s_expression = atomic_symbol \
	              / "(" s_expression "."s_expression ")" \
	              / list 
	
	list = "(" s_expression < s_expression > ")"
	
	atomic_symbol = letter atom_part
	
	atom_part = empty / letter atom_part / number atom_part
	
	letter = "a" / "b" / " ..." / "z"
	
	number = "1" / "2" / " ..." / "9"
	
	empty = " "


想要实现MiniLisp的Parser，首先要理解这个BNF规则。

## <a name="hh3"></a> MiniLisp的jj文件 ##

&nbsp;
&nbsp;
&nbsp;
&nbsp;
以下是用JavaCC生成MiniLisp
 Parser的jj文件。用javacc编译之后，会报一个警告`117行和118行发生conflict`。但是笔者已经加上`LOOKAHEAD(2)`了。
不知道为什么还警告，而且也单独对这部分进行了测试，完全没有问题。另外，这个生成的Parser并没有构造AST。


```java
options {
  STATIC = false;
  DEBUG_PARSER = true;
  DEBUG_LOOKAHEAD = true;
  DEBUG_TOKEN_MANAGER = false;
  ERROR_REPORTING = true;
  JAVA_UNICODE_ESCAPE = false;
  UNICODE_INPUT = false;
  IGNORE_CASE = false;
  USER_TOKEN_MANAGER = false;
  USER_CHAR_STREAM = false;
  BUILD_PARSER = true;
  BUILD_TOKEN_MANAGER = true;
  SANITY_CHECK = true;
  FORCE_LA_CHECK = true;
}

PARSER_BEGIN(MiniLisp)

package ym.minilisp;

import ym.minilisp.node.*;
import java.util.*;

public class MiniLisp {

  /** Main entry point. */
  public static void main(String args[]) throws ParseException {
    MiniLisp parser = new MiniLisp(System.in);
    parser.Input();
  }

}
PARSER_END(MiniLisp)


TOKEN :
{
      <EMPTY: [" ","\t","\n","\r"] ([" ","\t","\n","\r"])*>
    | <LP: "(">
    | <RP: ")">
    | <DOT: ".">
    | <MINUS: "-">
    | <PLUS: "+">
    | <EQ: "=">
    | <AND: "and">
    | <NOT: "not">
    | <OR: "or">
    | <GT: ">">
    | <LT: "<">
    | <LE: "<=">
    | <GE: ">=">
    | <SQUOTE: "'">
    | <QUOTE: "quote">
    | <NUM: ["1"-"9"] ( ["0"-"9"] )* | "0">
    | <ID: (["a"-"z","A"-"Z","_","@","?","$","%","*"]) (~["\n","\r"," ","(",")","\t","#",";","{","}","[","]"])* >
    | <COMMENT: ([";"])(~["\n","\r"])* ["\n","\r"]>
}


/** Root production. */
void Input() :
{}
{
    ( Expr() )*  <EOF>
}

void Expr():
{}
{
      NonSExpr()
    | SExpr()
}


void NonSExpr():
{}
{
    <EMPTY>
   |<COMMENT>
}


void SExpr() :
{}
{
      SymbolExpr()
    | <LP> (NonSExpr())* (SExpr() (NonSExpr())* )*  [<DOT> (NonSExpr())*  (SExpr() (NonSExpr())* )*] <RP>
    | SQuoteExpr()
}

void SQuoteExpr():
{}
{
    <SQUOTE> SExpr()
}


void SymbolExpr():
{}
{
    Symbol() LOOKAHEAD({ getToken(1).kind == LP || getToken(1).kind == RP|| getToken(1).kind == DOT || getToken(1).kind == COMMENT || getToken(1).kind == EMPTY })
}

void Symbol():
{}
{
       <PLUS>
    |  <EQ>
    |  <AND>
    |  <NOT>
    |  <OR>
    |  <GT>
    |  <LT>
    |  <LE>
    |  <GE>
    |  LOOKAHEAD(2) <MINUS> <NUM>
    |  <MINUS>
    |  <NUM>
    |  <ID>
}
```


## <a name="hh4"></a> 测试代码 ##

&nbsp;
&nbsp;
&nbsp;
&nbsp;
以下是对生成的MiniLisp.java文件进行测试的类。其中`test14`和`test15`是对
MiniLisp项目下的life.lisp和nqueens.lisp文件内容完整解析测试。
没有报错，说明jj中的规则可以解析MiniLisp。

```java
package ym.minilisp;

import java.io.StringReader;
import junit.framework.TestCase;
import org.junit.Test;

public class TestParser extends TestCase {

    @Test
    public void test1() throws ParseException {
        String s = "((a.b).(b.(c)))";
        call(s);
    }

    @Test
    public void test2() throws ParseException {
        String s = "(a b c)";
        call(s);
        s = "(a b . c)";
        call(s);
    }

    @Test
    public void test3() throws ParseException {
        String s = "(a .(b c))";
        call(s);
    }

    @Test
    public void test4() throws ParseException {
        String s = " ( ( a b ) . ( b c ) ) ";
        call(s);
    }

    @Test
    public void test5() throws ParseException {
        String s = "( a ( a b )  ( b c ) ) ";
        call(s);
    }

    @Test
    public void test6() throws ParseException {
        String s = "(define a 1) (define b -1) ";
        call(s);
    }

    @Test
    public void test7() throws ParseException {
        String s = " (+ 1 -2 a b (- 1 2)) ";
        call(s);
    }

    @Test
    public void test8() throws ParseException {
        String s = " (defun next (board x y)\n"
                + "  (let c (count board x y)\n"
                + "       (if (alive? board x y)\n"
                + "           (or (= c 2) (= c 3))\n"
                + "         (= c 3))))";
        System.out.println(s);
        call(s);
    }

    @Test
    public void test9() throws ParseException {
        String s = "(defun count (board x y)\n"
                + "  (let at (lambda (x y)\n"
                + "            (if (alive? board x y) 1 0))\n"
                + "       (+ (at (- x 1) (- y 1))\n"
                + "          (at (- x 1) y)\n"
                + "          (at (- x 1) (+ y 1))\n"
                + "          (at x (- y 1))\n"
                + "          (at x (+ y 1))\n"
                + "          (at (+ x 1) (- y 1))\n"
                + "          (at (+ x 1) y)\n"
                + "          (at (+ x 1) (+ y 1)))))";
        System.out.println(s);
        call(s);
    }

    @Test
    public void test10() throws ParseException {
        String s = " '(+ 1 2) ";
        call(s);
    }

    @Test
    public void test11() throws ParseException {
        String s = "(cons '1 '2)";
        call(s);
    }

    @Test
    public void test12() throws ParseException {
        String s = "(defmacro progn (expr . rest)\n"
                + "  (list (cons 'lambda (cons () (cons expr rest)))))";
        call(s);
    }

    @Test
    public void test13() throws ParseException {
        String s = ";;fadfsdfasdfasdfasdfa\n"
                + "(cons '1 '2)";
        call(s);
    }

    @Test
    public void test131() throws ParseException {
        String s = "(cons ;;fadfsdfasdfasdfasdfa\n"
                + "  '1 '2)";
        call(s);
    }

    @Test
    public void test132() throws ParseException {
        String s = ";;fadfsdfasdfasdfasdfa\n"
                + "  \n"
                + ";;fadfsdfasdfasdfasdf\n";

        call(s);
    }

    @Test
    public void test133() throws ParseException {
        String s = "(list ;;fadfsdfasdfasdfasdfa\n"
                + "  a  ;;fadfsdfasdfasdfasdfa\n "
                + "b)";
        call(s);
    }

    @Test
    public void test14() throws ParseException {
        String s = ";;;\n"
                + ";;; Conway's game of life\n"
                + ";;;\n"
                + "\n"
                + ";; (progn expr ...)\n"
                + ";; => ((lambda () expr ...))\n"
                + "(defmacro progn (expr . rest)\n"
                + "  (list (cons 'lambda (cons () (cons expr rest)))))\n"
                + "\n"
                + "(defun list (x . y)\n"
                + "  (cons x y))\n"
                + "\n"
                + "(defun not (x)\n"
                + "  (if x () t))\n"
                + "\n"
                + ";; (let var val body ...)\n"
                + ";; => ((lambda (var) body ...) val)\n"
                + "(defmacro let (var val . body)\n"
                + "  (cons (cons 'lambda (cons (list var) body))\n"
                + "\t(list val)))\n"
                + "\n"
                + ";; (and e1 e2 ...)\n"
                + ";; => (if e1 (and e2 ...))\n"
                + ";; (and e1)\n"
                + ";; => e1\n"
                + "(defmacro and (expr . rest)\n"
                + "  (if rest\n"
                + "      (list 'if expr (cons 'and rest))\n"
                + "    expr))\n"
                + "\n"
                + ";; (or e1 e2 ...)\n"
                + ";; => (let <tmp> e1\n"
                + ";;      (if <tmp> <tmp> (or e2 ...)))\n"
                + ";; (or e1)\n"
                + ";; => e1\n"
                + ";;\n"
                + ";; The reason to use the temporary variables is to avoid evaluating the\n"
                + ";; arguments more than once.\n"
                + "(defmacro or (expr . rest)\n"
                + "  (if rest\n"
                + "      (let var (gensym)\n"
                + "           (list 'let var expr\n"
                + "                 (list 'if var var (cons 'or rest))))\n"
                + "    expr))\n"
                + "\n"
                + ";; (when expr body ...)\n"
                + ";; => (if expr (progn body ...))\n"
                + "(defmacro when (expr . body)\n"
                + "  (cons 'if (cons expr (list (cons 'progn body)))))\n"
                + "\n"
                + ";; (unless expr body ...)\n"
                + ";; => (if expr () body ...)\n"
                + "(defmacro unless (expr . body)\n"
                + "  (cons 'if (cons expr (cons () body))))\n"
                + "\n"
                + ";;;\n"
                + ";;; Numeric operators\n"
                + ";;;\n"
                + "\n"
                + "(defun <= (e1 e2)\n"
                + "  (or (< e1 e2)\n"
                + "      (= e1 e2)))\n"
                + "\n"
                + ";;;\n"
                + ";;; List operators\n"
                + ";;;\n"
                + "\n"
                + ";;; Applies each element of lis to fn, and returns their return values as a list.\n"
                + "(defun map (lis fn)\n"
                + "  (when lis\n"
                + "    (cons (fn (car lis))\n"
                + "\t  (map (cdr lis) fn))))\n"
                + "\n"
                + ";; Returns nth element of lis.\n"
                + "(defun nth (lis n)\n"
                + "  (if (= n 0)\n"
                + "      (car lis)\n"
                + "    (nth (cdr lis) (- n 1))))\n"
                + "\n"
                + ";; Returns the nth tail of lis.\n"
                + "(defun nth-tail (lis n)\n"
                + "  (if (= n 0)\n"
                + "      lis\n"
                + "    (nth-tail (cdr lis) (- n 1))))\n"
                + "\n"
                + ";; Returns a list consists of m .. n-1 integers.\n"
                + "(defun %iota (m n)\n"
                + "  (unless (<= n m)\n"
                + "    (cons m (%iota (+ m 1) n))))\n"
                + "\n"
                + ";; Returns a list consists of 0 ... n-1 integers.\n"
                + "(defun iota (n)\n"
                + "  (%iota 0 n))\n"
                + "\n"
                + ";;;\n"
                + ";;; Main\n"
                + ";;;\n"
                + "\n"
                + "(define width 10)\n"
                + "(define height 10)\n"
                + "\n"
                + ";; Returns location (x, y)'s element.\n"
                + "(defun get (board x y)\n"
                + "  (nth (nth board y) x))\n"
                + "\n"
                + ";; Returns true if location (x, y)'s value is \"@\".\n"
                + "(defun alive? (board x y)\n"
                + "  (and (<= 0 x)\n"
                + "       (< x height)\n"
                + "       (<= 0 y)\n"
                + "       (< y width)\n"
                + "       (eq (get board x y) '@)))\n"
                + "\n"
                + ";; Print out the given board.\n"
                + "(defun print (board)\n"
                + "  (if (not board)\n"
                + "      '$\n"
                + "    (println (car board))\n"
                + "    (print (cdr board))))\n"
                + "\n"
                + "(defun count (board x y)\n"
                + "  (let at (lambda (x y)\n"
                + "            (if (alive? board x y) 1 0))\n"
                + "       (+ (at (- x 1) (- y 1))\n"
                + "          (at (- x 1) y)\n"
                + "          (at (- x 1) (+ y 1))\n"
                + "          (at x (- y 1))\n"
                + "          (at x (+ y 1))\n"
                + "          (at (+ x 1) (- y 1))\n"
                + "          (at (+ x 1) y)\n"
                + "          (at (+ x 1) (+ y 1)))))\n"
                + "\n"
                + "(defun next (board x y)\n"
                + "  (let c (count board x y)\n"
                + "       (if (alive? board x y)\n"
                + "           (or (= c 2) (= c 3))\n"
                + "         (= c 3))))\n"
                + "\n"
                + "(defun run (board)\n"
                + "  (while t\n"
                + "    (print board)\n"
                + "    (println '*)\n"
                + "    (let newboard (map (iota height)\n"
                + "                       (lambda (y)\n"
                + "                         (map (iota width)\n"
                + "                              (lambda (x)\n"
                + "                                (if (next board x y) '@ '_)))))\n"
                + "         (setq board newboard))))\n"
                + "\n"
                + "(run '((_ _ _ _ _ _ _ _ _ _)\n"
                + "       (_ _ _ _ _ _ _ _ _ _)\n"
                + "       (_ _ _ _ _ _ _ _ _ _)\n"
                + "       (_ _ _ _ _ _ _ _ _ _)\n"
                + "       (_ _ _ _ _ _ _ _ _ _)\n"
                + "       (_ _ _ _ _ _ _ _ _ _)\n"
                + "       (_ _ _ _ _ _ _ _ _ _)\n"
                + "       (_ @ @ @ _ _ _ _ _ _)\n"
                + "       (_ _ _ @ _ _ _ _ _ _)\n"
                + "       (_ _ @ _ _ _ _ _ _ _)))\n";
        call(s);
    }

    @Test
    public void test15() throws ParseException {
        String s = ";;;\n"
                + ";;; N-queens puzzle solver.\n"
                + ";;;\n"
                + ";;; The N queens puzzle is the problem of placing N chess queens on an N x N\n"
                + ";;; chessboard so that no two queens attack each\n"
                + ";;; other. http://en.wikipedia.org/wiki/Eight_queens_puzzle\n"
                + ";;;\n"
                + ";;; This program solves N-queens puzzle by depth-first backtracking.\n"
                + ";;;\n"
                + "\n"
                + ";;;\n"
                + ";;; Basic macros\n"
                + ";;;\n"
                + ";;; Because the language does not have quasiquote, we need to construct an\n"
                + ";;; expanded form using cons and list.\n"
                + ";;;\n"
                + "\n"
                + ";; (progn expr ...)\n"
                + ";; => ((lambda () expr ...))\n"
                + "(defmacro progn (expr . rest)\n"
                + "  (list (cons 'lambda (cons () (cons expr rest)))))\n"
                + "\n"
                + "(defun list (x . y)\n"
                + "  (cons x y))\n"
                + "\n"
                + "(defun not (x)\n"
                + "  (if x () t))\n"
                + "\n"
                + ";; (let1 var val body ...)\n"
                + ";; => ((lambda (var) body ...) val)\n"
                + "(defmacro let1 (var val . body)\n"
                + "  (cons (cons 'lambda (cons (list var) body))\n"
                + "\t(list val)))\n"
                + "\n"
                + ";; (and e1 e2 ...)\n"
                + ";; => (if e1 (and e2 ...))\n"
                + ";; (and e1)\n"
                + ";; => e1\n"
                + "(defmacro and (expr . rest)\n"
                + "  (if rest\n"
                + "      (list 'if expr (cons 'and rest))\n"
                + "    expr))\n"
                + "\n"
                + ";; (or e1 e2 ...)\n"
                + ";; => (let1 <tmp> e1\n"
                + ";;      (if <tmp> <tmp> (or e2 ...)))\n"
                + ";; (or e1)\n"
                + ";; => e1\n"
                + ";;\n"
                + ";; The reason to use the temporary variables is to avoid evaluating the\n"
                + ";; arguments more than once.\n"
                + "(defmacro or (expr . rest)\n"
                + "  (if rest\n"
                + "      (let1 var (gensym)\n"
                + "\t    (list 'let1 var expr\n"
                + "\t\t  (list 'if var var (cons 'or rest))))\n"
                + "    expr))\n"
                + "\n"
                + ";; (when expr body ...)\n"
                + ";; => (if expr (progn body ...))\n"
                + "(defmacro when (expr . body)\n"
                + "  (cons 'if (cons expr (list (cons 'progn body)))))\n"
                + "\n"
                + ";; (unless expr body ...)\n"
                + ";; => (if expr () body ...)\n"
                + "(defmacro unless (expr . body)\n"
                + "  (cons 'if (cons expr (cons () body))))\n"
                + "\n"
                + ";;;\n"
                + ";;; Numeric operators\n"
                + ";;;\n"
                + "\n"
                + "(defun <= (e1 e2)\n"
                + "  (or (< e1 e2)\n"
                + "      (= e1 e2)))\n"
                + "\n"
                + ";;;\n"
                + ";;; List operators\n"
                + ";;;\n"
                + "\n"
                + ";; Applies each element of lis to pred. If pred returns a true value, terminate\n"
                + ";; the evaluation and returns pred's return value. If all of them return (),\n"
                + ";; returns ().\n"
                + "(defun any (lis pred)\n"
                + "  (when lis\n"
                + "    (or (pred (car lis))\n"
                + "\t(any (cdr lis) pred))))\n"
                + "\n"
                + ";;; Applies each element of lis to fn, and returns their return values as a list.\n"
                + "(defun map (lis fn)\n"
                + "  (when lis\n"
                + "    (cons (fn (car lis))\n"
                + "\t  (map (cdr lis) fn))))\n"
                + "\n"
                + ";; Returns nth element of lis.\n"
                + "(defun nth (lis n)\n"
                + "  (if (= n 0)\n"
                + "      (car lis)\n"
                + "    (nth (cdr lis) (- n 1))))\n"
                + "\n"
                + ";; Returns the nth tail of lis.\n"
                + "(defun nth-tail (lis n)\n"
                + "  (if (= n 0)\n"
                + "      lis\n"
                + "    (nth-tail (cdr lis) (- n 1))))\n"
                + "\n"
                + ";; Returns a list consists of m .. n-1 integers.\n"
                + "(defun %iota (m n)\n"
                + "  (unless (<= n m)\n"
                + "    (cons m (%iota (+ m 1) n))))\n"
                + "\n"
                + ";; Returns a list consists of 0 ... n-1 integers.\n"
                + "(defun iota (n)\n"
                + "  (%iota 0 n))\n"
                + "\n"
                + ";; Returns a new list whose length is len and all members are init.\n"
                + "(defun make-list (len init)\n"
                + "  (unless (= len 0)\n"
                + "    (cons init (make-list (- len 1) init))))\n"
                + "\n"
                + ";; Applies fn to each element of lis.\n"
                + "(defun for-each (lis fn)\n"
                + "  (or (not lis)\n"
                + "      (progn (fn (car lis))\n"
                + "\t     (for-each (cdr lis) fn))))\n"
                + "\n"
                + ";;;\n"
                + ";;; N-queens solver\n"
                + ";;;\n"
                + "\n"
                + ";; Creates size x size list filled with symbol \"x\".\n"
                + "(defun make-board (size)\n"
                + "  (map (iota size)\n"
                + "       (lambda (_)\n"
                + "\t (make-list size 'x))))\n"
                + "\n"
                + ";; Returns location (x, y)'s element.\n"
                + "(defun get (board x y)\n"
                + "  (nth (nth board x) y))\n"
                + "\n"
                + ";; Set symbol \"@\" to location (x, y).\n"
                + "(defun set (board x y)\n"
                + "  (setcar (nth-tail (nth board x) y) '@))\n"
                + "\n"
                + ";; Set symbol \"x\" to location (x, y).\n"
                + "(defun clear (board x y)\n"
                + "  (setcar (nth-tail (nth board x) y) 'x))\n"
                + "\n"
                + ";; Returns true if location (x, y)'s value is \"@\".\n"
                + "(defun set? (board x y)\n"
                + "  (eq (get board x y) '@))\n"
                + "\n"
                + ";; Print out the given board.\n"
                + "(defun print (board)\n"
                + "  (if (not board)\n"
                + "      '$\n"
                + "    (println (car board))\n"
                + "    (print (cdr board))))\n"
                + "\n"
                + ";; Returns true if we cannot place a queen at position (x, y), assuming that\n"
                + ";; queens have already been placed on each row from 0 to x-1.\n"
                + "(defun conflict? (board x y)\n"
                + "  (any (iota x)\n"
                + "       (lambda (n)\n"
                + "\t (or\n"
                + "\t  ;; Check if there's no conflicting queen upward\n"
                + "\t  (set? board n y)\n"
                + "\t  ;; Upper left\n"
                + "\t  (let1 z (+ y (- n x))\n"
                + "\t\t(and (<= 0 z)\n"
                + "\t\t     (set? board n z)))\n"
                + "\t  ;; Upper right\n"
                + "\t  (let1 z (+ y (- x n))\n"
                + "\t\t(and (< z board-size)\n"
                + "\t\t     (set? board n z)))))))\n"
                + "\n"
                + ";; Find positions where we can place queens at row x, and continue searching for\n"
                + ";; the next row.\n"
                + "(defun %solve (board x)\n"
                + "  (if (= x board-size)\n"
                + "      ;; Problem solved\n"
                + "      (progn (print board)\n"
                + "\t     (println '$))\n"
                + "    (for-each (iota board-size)\n"
                + "\t      (lambda (y)\n"
                + "\t\t(unless (conflict? board x y)\n"
                + "\t\t  (set board x y)\n"
                + "\t\t  (%solve board (+ x 1))\n"
                + "\t\t  (clear board x y))))))\n"
                + "\n"
                + "(defun solve (board)\n"
                + "  (println 'start)\n"
                + "  (%solve board 0)\n"
                + "  (println 'done))\n"
                + "\n"
                + ";;;\n"
                + ";;; Main\n"
                + ";;;\n"
                + "\n"
                + "(define board-size 8)\n"
                + "(define board (make-board board-size))\n"
                + "(solve board)\n";
        call(s);
    }

    private void call(String s) throws ParseException {
        MiniLisp parser = new MiniLisp(new StringReader(s));
        parser.Input();
    }
}
```

