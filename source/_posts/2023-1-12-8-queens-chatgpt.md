---
title:  "通过ChatGPT实现Rust语言的八皇后算法"
date: 2023-1-12
author: alenym@qq.com
tags: 
  - ChatGPT
  - rust
  - 算法
katex: true 
mathjax: true
---

## ChatGPT是什么？ ##

[ChatGPT](https://openai.com/blog/chatgpt/)是基于`OpenAI`项目的聊天机器人。

`OpenAI`项目由特斯拉创建，而`ChatGPT`的母公司当前估值$29bln，据说微软准备购买$10bln。

<!-- more -->

目前ChatGPT不对中国开放，想要注册不光需要VPN，还需要手机短信验证。不过注册完成后登录不需要短信验证了。

具体怎么注册登录ChatGPT可以参考其它文章。

## 八皇后问题 ##

八皇后问题（英文：Eight queens），是由国际象棋棋手马克斯·贝瑟尔于1848年提出的问题，是回溯算法的典型案例。 
问题表述为：在8×8格的国际象棋上摆放8个皇后，使其不能互相攻击，
即任意两个皇后都不能处于同一行、同一列或同一斜线上，问有多少种摆法。 
高斯认为有76种方案。

![2023-1-12-8queens-problem](/images/2023-1-12-8queens-problem.png)

## 通过ChatGPT实现Rust语言的八皇后算法 ##

直接问ChatGPT, "How to write eight queens algorithm in rust?"
如下图所示，直接就把rust代码实现显示出来，并进行了说明。

![2023-1-12-8queens-chatgpt](/images/2023-1-12-8queens-chatgpt.png)

把rust代码copy出来，增加测试代码`test_eight_queen()`。

```rust
fn eight_queens() {
    let mut board = vec![-1; 8];

    solve(&mut board, 0);
}

fn solve(board: &mut Vec<i32>, target_row: i32) {
    if target_row == 8 {
        print_board(board);
        return;
    }

    for column in 0..8 {
        if is_safe(board, target_row, column) {
            board[target_row as usize] = column as i32;
            solve(board, target_row + 1);
        }
    }
}

fn is_safe(board: &Vec<i32>, row: i32, column: i32) -> bool {
    for r in 0..row {
        let c = board[r as usize];

        if c == column ||
            (row - r).abs() == (column - c).abs() {
            return false;
        }
    }

    return true;
}

fn print_board(board: &Vec<i32>) {
    for r in 0..8 {
        for c in 0..8 {
            if board[r as usize] == c as i32 {
                print!("Q ");
            } else {
                print!(". ");
            }
        }

        println!("");
    }

    println!("");
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_eight_queen() {
        super::eight_queens();
    }
}
```

## 运行 ## 

直接运行，没有错误。

```shell
hello $ cargo test --bin hello eight_queens::tests::test_eight_queen -- --show-output
    Finished test [unoptimized + debuginfo] target(s) in 0.11s
     Running unittests src/main.rs (target/debug/deps/hello-257baa7e5ed28221)

running 1 test
test eight_queens::tests::test_eight_queen ... ok

successes:

---- eight_queens::tests::test_eight_queen stdout ----
Q . . . . . . . 
. . . . Q . . . 
. . . . . . . Q 
. . . . . Q . . 
. . Q . . . . . 
. . . . . . Q . 
. Q . . . . . . 
. . . Q . . . . 

Q . . . . . . . 
. . . . . Q . . 
. . . . . . . Q 
. . Q . . . . . 
. . . . . . Q . 
. . . Q . . . . 
. Q . . . . . . 
. . . . Q . . . 

Q . . . . . . . 
. . . . . . Q . 
. . . Q . . . . 
. . . . . Q . . 
. . . . . . . Q 
. Q . . . . . . 
. . . . Q . . . 
. . Q . . . . . 

Q . . . . . . . 
. . . . . . Q . 
. . . . Q . . . 
. . . . . . . Q 
. Q . . . . . . 
. . . Q . . . . 
. . . . . Q . . 
. . Q . . . . . 

. Q . . . . . . 
. . . Q . . . . 
. . . . . Q . . 
. . . . . . . Q 
. . Q . . . . . 
Q . . . . . . . 
. . . . . . Q . 
. . . . Q . . . 

. Q . . . . . . 
. . . . Q . . . 
. . . . . . Q . 
Q . . . . . . . 
. . Q . . . . . 
. . . . . . . Q 
. . . . . Q . . 
. . . Q . . . . 

. Q . . . . . . 
. . . . Q . . . 
. . . . . . Q . 
. . . Q . . . . 
Q . . . . . . . 
. . . . . . . Q 
. . . . . Q . . 
. . Q . . . . . 

... ignore
...
...

successes:
    eight_queens::tests::test_eight_queen

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 22 filtered out; finished in 0.00s
```

## 最后 ##

ChatGPT给人非常惊艳的感觉。我考虑以后经常使用它，如果它一直免费的话。