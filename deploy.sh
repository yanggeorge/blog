#!/bin/bash

# 获取当前脚本的绝对路径
BASE_PATH=$(readlink -f "$0")

# 获取当前脚本所在的目录
BASE_DIR=$(dirname "$SCRIPT_PATH")

cd $BASE_DIR/blog  && hexo clean && hexo g && mkdir ./public/en && cd ../blog_en && hexo clean && hexo g && cd ../blog && cp -r ../blog_en/public/. ./public/en/  && hexo d
