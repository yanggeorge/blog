---
title:  "玩一下LangChain"
date: 2023-6-8
author: alenym@qq.com
tags: 
  - langchain
  - openai
katex: true 
mathjax: true
---

## 什么是LangChain ##

自从ChatGPT出现以来，就一直在使用，那么ChatGPT毕竟是有局限性的，因为ChatGPT训练的语料是有限的。很多问题回答不了，
也经常会胡言乱语闹笑话。

但是ChatGPT背后的大语言模型LLM是可以扩展的，也就是说，可以把特定的领域知识让LLM（大语言模型）学习。这样就在一定
程度上解决了局限性。

而[LangChain项目](https://github.com/hwchase17/langchain)就是这样的杀手锏，这里是[官方文档](https://python.langchain.com/en/latest/)。

<!-- more -->

本文代码和例子参考了[使用langchain打造自己的大型语言模型(LLMs)](https://blog.csdn.net/weixin_42608414/article/details/129493302)，对中文资料进行处理。


## OpenAI的key ## 

LangChain是一个框架，如果要使用，则需要调用大语言模型的API。正好有一朋友申请了`OPENAI_API_KEY`，这样就可以开始
跑跑代码了。

## 代码 ##

以下是Python代码。

```python
import os
from langchain.embeddings.openai import OpenAIEmbeddings
from langchain.vectorstores import Chroma
from langchain.text_splitter import TokenTextSplitter
from langchain.llms import OpenAI
from langchain.document_loaders import DirectoryLoader
from langchain.chains import RetrievalQAWithSourcesChain, ChatVectorDBChain
import jieba as jb

os.environ["OPENAI_API_KEY"] = "sk-xxxxxxx"  # <-- 这里替换为申请的key


def preprocess_txt():
    """
由于中文的语法的特殊性，对于中文的文档必须要做一些预处理工作：词语的拆分，
也就是要把中文的语句拆分成一个个基本的词语单位，这里我们会用的一个分词工具：jieba，
它会帮助我们对资料库中的所有文本文件进行分词处理。不过我们首先将这3个时事新闻的文本文件放置到Data文件夹下面，
然后在data文件夹下面再建一个子文件夹:cut, 用来存放被分词过的文档：
    """
    files = ['天龙八部.txt']

    for file in files:
        # 读取data文件夹中的中文文档
        my_file = f"./data/{file}"
        with open(my_file, "r", encoding='utf-8') as f:
            data = f.read()

        # 对中文文档进行分词处理
        cut_data = " ".join([w for w in list(jb.cut(data))])
        # 分词处理后的文档保存到data文件夹中的cut子文件夹中
        cut_file = f"./data/cut/cut_{file}"
        with open(cut_file, 'w') as f:
            f.write(cut_data)
            f.close()


def embeddings():
    # 加载文档
    loader = DirectoryLoader('./data/cut', glob='**/*.txt')
    docs = loader.load()
    # 文档切块
    text_splitter = TokenTextSplitter(chunk_size=1000, chunk_overlap=0)
    doc_texts = text_splitter.split_documents(docs)
    # 调用openai Embeddings
    embeddings = OpenAIEmbeddings()
    # 向量化
    vectordb = Chroma.from_documents(doc_texts, embeddings, persist_directory="./data/cut")
    vectordb.persist()


def ask():
    embeddings = OpenAIEmbeddings()

    docsearch = Chroma(persist_directory="./data/cut", embedding_function=embeddings)

    chain = ChatVectorDBChain.from_llm(OpenAI(temperature=0, model_name="gpt-3.5-turbo"), docsearch,
                                       return_source_documents=True)

    while True:
        try:
            # code to be executed repeatedly
            user_input = input("What's your question: ")

            chat_history = []
            result = chain({"question": user_input, "chat_history": chat_history})

            print("Answer: " + result["answer"].replace('\n', ' '))
        except KeyboardInterrupt:
            # code to be executed when Ctrl+C is pressed
            break


if __name__ == '__main__':
    preprocess_txt()
    embeddings()
    ask()
```

## 代码依赖模块 ## 

Python3.11安装依赖

```shell 
pip install -r requirements.txt
```

requirements.txt内容如下：

```text 
aiohttp==3.8.4
aiosignal==1.3.1
anyio==3.7.0
argilla==1.8.0
async-timeout==4.0.2
attrs==23.1.0
backoff==2.2.1
certifi==2023.5.7
cffi==1.15.1
chardet==5.1.0
charset-normalizer==3.1.0
chromadb==0.3.26
click==8.1.3
clickhouse-connect==0.6.0
coloredlogs==15.0.1
commonmark==0.9.1
contourpy==1.0.7
cryptography==41.0.1
cycler==0.11.0
dataclasses-json==0.5.7
Deprecated==1.2.14
duckdb==0.8.0
et-xmlfile==1.1.0
fastapi==0.96.0
flatbuffers==23.5.26
fonttools==4.39.4
frozenlist==1.3.3
greenlet==2.0.2
h11==0.14.0
hnswlib==0.7.0
httpcore==0.16.3
httptools==0.5.0
httpx==0.23.3
humanfriendly==10.0
idna==3.4
jieba==0.42.1
joblib==1.2.0
kiwisolver==1.4.4
langchain==0.0.191
lxml==4.9.2
lz4==4.3.2
Markdown==3.4.3
marshmallow==3.19.0
marshmallow-enum==1.5.1
matplotlib==3.7.1
monotonic==1.6
mpmath==1.3.0
msg-parser==1.2.0
multidict==6.0.4
mypy-extensions==1.0.0
nltk==3.8.1
numexpr==2.8.4
numpy==1.23.5
olefile==0.46
onnxruntime==1.15.0
openai==0.27.7
openapi-schema-pydantic==1.2.4
openpyxl==3.1.2
overrides==7.3.1
packaging==23.1
pandas==1.5.3
pdf2image==1.16.3
pdfminer.six==20221105
Pillow==9.5.0
posthog==3.0.1
protobuf==4.23.2
pulsar-client==3.2.0
pycparser==2.21
pydantic==1.10.8
Pygments==2.15.1
pypandoc==1.11
pyparsing==3.0.9
python-dateutil==2.8.2
python-docx==0.8.11
python-dotenv==1.0.0
python-magic==0.4.27
python-pptx==0.6.21
pytz==2023.3
PyYAML==6.0
regex==2023.6.3
requests==2.31.0
rfc3986==1.5.0
rich==13.0.1
six==1.16.0
sniffio==1.3.0
SQLAlchemy==2.0.15
starlette==0.27.0
sympy==1.12
tabulate==0.9.0
tenacity==8.2.2
tiktoken==0.4.0
tokenizers==0.13.3
tqdm==4.65.0
typer==0.9.0
typing-inspect==0.9.0
typing_extensions==4.6.3
tzdata==2023.3
unstructured==0.7.1
urllib3==2.0.2
uvicorn==0.22.0
uvloop==0.17.0
watchfiles==0.19.0
websockets==11.0.3
wrapt==1.14.1
xlrd==2.0.1
XlsxWriter==3.1.2
yarl==1.9.2
zstandard==0.21.0
```

## 文本 ## 

而文本则放在 "./data/" 目录下，

`天龙八部.txt` 内容如下，就是一些明确的信息。

```text 
段誉和乔峰，虚竹是兄弟。

阿朱喜欢乔峰。

段誉喜欢王语嫣。
```

如果直接问ChatGPT，"段誉的兄弟是谁", "段誉有几个兄弟"则ChatGPT回答有些混乱。

![chatgpt-duanyu-brothers](./images/chatgpt-duanyu-brothers.png)

## 运行测试 ##

直接运行后，测试提问，如下。

![langchain1](./images/langchain-duanyu1.png)

![langchain1](./images/langchain-duanyu2.png)

很有意思。

## 总结 ##

1. 中文需要进行分词，与英文的处理不同。
2. 需要避免4096 TOKEN的限制，则只能使用文章中提到模型建立Chain。
```python
ChatVectorDBChain.from_llm(OpenAI(temperature=0, model_name="gpt-3.5-turbo"), docsearch,
                                       return_source_documents=True)
```
3. 还是需要VPN才能使用，另外OPEN_API_KEY是需要花钱的。

## 参考 ##

-  [使用langchain打造自己的大型语言模型(LLMs)](https://blog.csdn.net/weixin_42608414/article/details/129493302)


