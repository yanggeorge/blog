---
title: 使用pandas.read_csv()读取csv文件
categories:  Python 技巧
author: alenym@qq.com
---



## <a name="hh0"></a> 问题 ##

以下Python代码实现对`Excel`转存的csv文件进行读取。
```python
import pandas as pd
df = pd.read_csv(file_path + file_name + ".csv", encoding="gbk")
```

<!-- more -->

把`csv`文件入库是一件脏活。表面上看`csv`文件是一个非常简单的
逗号分隔符文件。但是其实不然。`Excel`转存的`csv`文件并不是标准的以逗号作为分隔符，
并且对所有的项用双引号包裹。现在我就遇到了从`Oracle`导出的`csv`文件，以上的代码
不起作用了。

## <a name="hh1"></a> 解决问题 ##

究竟怎么回事呢，找了一圈也没有发现使用`pandas.read_csv()`读取
这种标准csv文件的方法。还是先把问题简化一下，看看`Python`的`csv模块`是如何读取的吧。
简单的查找就可以找到答案。

```python
import csv
csv.register_dialect(
    'mydialect',
    delimiter = ',',
    quotechar = '"',
    doublequote = True,
    skipinitialspace = True,
    lineterminator = '\r\n',
    quoting = csv.QUOTE_MINIMAL)

print('\n Output from an iterable object created from the csv file')
with open('smallsample.csv', 'rb') as mycsvfile:
    thedata = csv.reader(mycsvfile, dialect='mydialect')
    for row in thedata:
        print(row[0]+"\t \t"+row[1]+"\t \t"+row[4])
```

好的，`pandas.read_csv()`肯定是要调用csv模块的，那么看看
它的方法参数表吧。

> pandas.read_csv(filepath_or_buffer, sep=', ', delimiter=None, header='infer', names=None, index_col=None, usecols=None, squeeze=False, prefix=None, mangle_dupe_cols=True, dtype=None, engine=None, converters=None, true_values=None, false_values=None, skipinitialspace=False, skiprows=None, nrows=None, na_values=None, keep_default_na=True, na_filter=True, verbose=False, skip_blank_lines=True, parse_dates=False, infer_datetime_format=False, keep_date_col=False, date_parser=None, dayfirst=False, iterator=False, chunksize=None, compression='infer', thousands=None, decimal='.', lineterminator=None, quotechar='"', quoting=0, escapechar=None, comment=None, encoding=None, **dialect=None**, tupleize_cols=False, error_bad_lines=True, warn_bad_lines=True, skipfooter=0, skip_footer=0, doublequote=True, delim_whitespace=False, as_recarray=False, compact_ints=False, use_unsigned=False, low_memory=True, buffer_lines=None, memory_map=False, float_precision=None)[source]¶

真是够长的，还是搜一下有没有`dialect=`，呵呵，果然有。

> dialect : str or csv.Dialect instance, default None  <br/>
>          If None defaults to Excel dialect. Ignored if sep longer than 1 char See csv.Dialect documentation for more details

那么问题解决了。把第一段代码改改吧。


```python
import pandas as pd
df = pd.read_csv(file_path + file_name + ".csv", encoding="gbk", dialect='mydialect')
```

一运行还是报错，这是怎么回事呢，编码换成`utf8`，也不行。最后才发现
需要使用`gb18030`才行。即使使用`chardet`的编码探测模块，也不一定能探测出来，因为整个文档
只有少数字符是超出了`gbk`，所以不可能既高效又准确的解决这个问题。

