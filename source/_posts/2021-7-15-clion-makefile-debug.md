---
title:  CLion2021调试Makefile项目
date: 2021-7-15
author: alenym@qq.com
tags: 
  - clion
  - makefile
  - debug
---

## CLion介绍 ##

`CLion`是一款针对C/C++项目的跨平台的集成IDE（A cross-platform IDE for C and C++）。2020版本以前，只支持cmake项目，
但是2021版本对Makefile项目的支持度增加了。我们看看如何对Makefile项目进行断点调试。

<!-- more -->

我们用一个实际的项目作为例子。

## Go1.4源码 ## 

Go语言项目从源码编译有几种方式，其中一种方式是基于[Bootstrap toolchain from C source code](https://golang.org/doc/install/source#bootstrapFromSource),
也就是说，首先编译Go 1.4版本，然后用编译出来的`Go`，编译最新的Go版本。(**UPDATE: Mac12.1 Monterey系统上不支持**)

那么我下载这个Go1.4版本，[go1.4-bootstrap-20171003.tar.gz](https://dl.google.com/go/go1.4-bootstrap-20171003.tar.gz)，
解压到某个路径下。
```
~/work/go1.4/ ls          
AUTHORS      LICENSE      README       api          doc          include      misc         robots.txt   test
CONTRIBUTORS PATENTS      VERSION      bin          favicon.ico  lib          pkg          src
```

进入src路径下，运行make.bash文件，则开始编译。（当然需要build相关的工具）。为了看清楚bash脚本执行的内容，我们修改make.bash的
第一行改为 `set -ex`, 这样会打印详细的执行内容如下，

``` 
g1.4/src/ $  ./make.bash 
+ '[' '!' -f run.bash ']'
+ case "$(uname)" in
++ uname
+ ld --version
+ grep 'gold.* 2\.20'
+ for se_mount in /selinux /sys/fs/selinux
+ '[' -d /selinux -a -f /selinux/booleans/allow_execstack -a -x /usr/sbin/selinuxenabled ']'
+ for se_mount in /selinux /sys/fs/selinux
+ '[' -d /sys/fs/selinux -a -f /sys/fs/selinux/booleans/allow_execstack -a -x /usr/sbin/selinuxenabled ']'
++ uname -s
+ '[' Darwin == GNU/kFreeBSD ']'
+ rm -f ./runtime/runtime_defs.go
+ echo '# Building C bootstrap tool.'
# Building C bootstrap tool.
+ echo cmd/dist
cmd/dist
++ cd ..
++ pwd
+ export GOROOT=/Users/ym/work/go1.4
+ GOROOT=/Users/ym/work/go1.4
+ GOROOT_FINAL=/Users/ym/work/go1.4
+ DEFGOROOT='-DGOROOT_FINAL="/Users/ym/work/go1.4"'
+ mflag=
+ case "$GOHOSTARCH" in
++ uname
+ '[' Darwin == Darwin ']'
+ mflag=' -mmacosx-version-min=10.6'
++ type -t gcc
++ type -t clang
+ '[' -z '' -a -z file -a -n file ']'
+ gcc -mmacosx-version-min=10.6 -O2 -Wall -Werror -o cmd/dist/dist -Icmd/dist '-DGOROOT_FINAL="/Users/ym/work/go1.4"' cmd/dist/arm.c cmd/dist/buf.c cmd/dist/build.c cmd/dist/buildgc.c cmd/dist/buildgo.c cmd/dist/buildruntime.c cmd/dist/main.c cmd/dist/plan9.c cmd/dist/unix.c cmd/dist/windows.c
++ ./cmd/dist/dist env -p
+ eval 'CC="clang"' 'CC_FOR_TARGET="clang"' 'GOROOT="/Users/ym/work/go1.4"' 'GOBIN="/Users/ym/me/go/test/bin"' 'GOARCH="amd64"' 'GOOS="darwin"' 'GOHOSTARCH="amd64"' 'GOHOSTOS="darwin"' 'GOTOOLDIR="/Users/ym/work/go1.4/pkg/tool/darwin_amd64"' 'GOCHAR="6"' 'PATH="/Users/ym/me/go/test/bin:/usr/local/opt/openssl@1.1/bin:/usr/local/opt/postgresql@12/bin:/Users/ym/work/go1.4/bin:/usr/local/Homebrew/bin:/usr/local/sbin:/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/go/bin:/usr/local/share/dotnet:~/.dotnet/tools:/Library/Apple/usr/bin:/Library/Frameworks/Mono.framework/Versions/Current/Commands:/Users/ym/mybin/apache-maven-3.6.0/bin:/Users/ym/me/go/test/bin:/Users/ym/.rvm/bin:/Users/ym/mybin/spark-2.4.3-bin-hadoop2.7/bin/"'
++ CC=clang
++ CC_FOR_TARGET=clang
++ GOROOT=/Users/ym/work/go1.4
++ GOBIN=/Users/ym/me/go/test/bin
++ GOARCH=amd64
++ GOOS=darwin
++ GOHOSTARCH=amd64
++ GOHOSTOS=darwin
++ GOTOOLDIR=/Users/ym/work/go1.4/pkg/tool/darwin_amd64
++ GOCHAR=6
++ PATH='/Users/ym/me/go/test/bin:/usr/local/opt/openssl@1.1/bin:/usr/local/opt/postgresql@12/bin:/Users/ym/work/go1.4/bin:/usr/local/Homebrew/bin:/usr/local/sbin:/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/go/bin:/usr/local/share/dotnet:~/.dotnet/tools:/Library/Apple/usr/bin:/Library/Frameworks/Mono.framework/Versions/Current/Commands:/Users/ym/mybin/apache-maven-3.6.0/bin:/Users/ym/me/go/test/bin:/Users/ym/.rvm/bin:/Users/ym/mybin/spark-2.4.3-bin-hadoop2.7/bin/'
+ '[' '' = true ']'
+ echo

+ '[' '' = --dist-tool ']'
+ echo '# Building compilers and Go bootstrap tool for host, darwin/amd64.'
# Building compilers and Go bootstrap tool for host, darwin/amd64.
+ buildall=-a
+ '[' '' = --no-clean ']'
+ ./cmd/dist/dist bootstrap -a -v
lib9
libbio
liblink
cmd/cc
cmd/gc
cmd/6l
/Users/ym/work/go1.4/src/cmd/6l/../ld/dwarf.c:1479:15: warning: implicit conversion from 'int' to 'char' changes value from 156 to -100 [-Wconstant-conversion]
/Users/ym/work/go1.4/src/cmd/6l/../ld/dwarf.c:1763:21: warning: implicit conversion from 'int' to 'char' changes value from 144 to -112 [-Wconstant-conversion]
/Users/ym/work/go1.4/src/cmd/6l/../ld/lib.h:168:13: note: expanded from macro 'cput'
cmd/6a
cmd/6c
/Users/ym/work/go1.4/src/cmd/6c/txt.c:995:28: warning: shifting a negative signed value is undefined [-Wshift-negative-value]
/Users/ym/work/go1.4/src/cmd/6c/txt.c:1045:28: warning: shifting a negative signed value is undefined [-Wshift-negative-value]
cmd/6g
/Users/ym/work/go1.4/src/cmd/6g/peep.c:771:13: warning: converting the enum constant to a boolean [-Wint-in-bool-context]
runtime
errors
sync/atomic
sync
io
unicode
unicode/utf8
unicode/utf16
bytes
math
strings
strconv
bufio
sort
container/heap
encoding/base64
syscall
time
os
reflect
fmt
encoding
encoding/json
flag
path/filepath
path
io/ioutil
log
regexp/syntax
regexp
go/token
go/scanner
go/ast
go/parser
os/exec
os/signal
net/url
text/template/parse
text/template
go/doc
go/build
cmd/go
+ cp cmd/dist/dist /Users/ym/work/go1.4/pkg/tool/darwin_amd64/dist
+ /Users/ym/work/go1.4/pkg/tool/darwin_amd64/go_bootstrap clean -i std
+ echo

+ '[' amd64 '!=' amd64 -o darwin '!=' darwin ']'
+ echo '# Building packages and commands for darwin/amd64.'
# Building packages and commands for darwin/amd64.
+ CC=clang
+ /Users/ym/work/go1.4/pkg/tool/darwin_amd64/go_bootstrap install -ccflags '' -gcflags '' -ldflags '' -v std
runtime
errors
sync/atomic
unicode
unicode/utf8
math
sort
encoding
unicode/utf16
container/list
sync
crypto/subtle
container/ring
image/color
runtime/race
container/heap
io
syscall
image/color/palette
hash
crypto/cipher
hash/crc32
crypto/hmac
hash/adler32
hash/crc64
hash/fnv
bytes
strings
bufio
text/tabwriter
path
html
compress/bzip2
time
strconv
math/rand
math/cmplx
os
reflect
regexp/syntax
crypto
encoding/base64
net/url
crypto/aes
crypto/rc4
crypto/md5
crypto/sha1
crypto/sha256
crypto/sha512
encoding/pem
encoding/ascii85
encoding/base32
image
path/filepath
net
os/signal
io/ioutil
os/exec
regexp
image/draw
image/jpeg
fmt
encoding/binary
cmd/pprof/internal/svg
crypto/des
index/suffixarray
cmd/internal/goobj
cmd/internal/rsc.io/arm/armasm
cmd/internal/rsc.io/x86/x86asm
debug/dwarf
debug/gosym
debug/plan9obj
flag
log
go/token
encoding/json
encoding/xml
text/template/parse
go/scanner
debug/elf
debug/macho
debug/pe
go/ast
compress/flate
text/template
math/big
encoding/hex
mime
net/textproto
cmd/internal/objfile
net/http/internal
compress/gzip
runtime/pprof
cmd/pack
cmd/pprof/internal/profile
cmd/pprof/internal/tempfile
archive/tar
archive/zip
cmd/addr2line
cmd/nm
crypto/elliptic
encoding/asn1
crypto/rand
go/parser
go/printer
go/doc
crypto/ecdsa
crypto/rsa
crypto/dsa
crypto/x509/pkix
mime/multipart
cmd/objdump
cmd/pprof/internal/plugin
crypto/x509
html/template
go/build
cmd/cgo
go/format
cmd/fix
cmd/gofmt
crypto/tls
cmd/pprof/internal/symbolizer
cmd/pprof/internal/symbolz
cmd/pprof/internal/report
cmd/yacc
compress/lzw
compress/zlib
database/sql/driver
database/sql
encoding/csv
encoding/gob
cmd/pprof/internal/commands
image/gif
cmd/pprof/internal/driver
image/png
log/syslog
net/mail
os/user
runtime/debug
testing
testing/iotest
net/http
net/smtp
testing/quick
text/scanner
cmd/go
cmd/pprof/internal/fetch
expvar
net/http/cgi
net/http/cookiejar
net/http/httptest
net/http/httputil
net/http/pprof
cmd/pprof
net/rpc
net/http/fcgi
net/rpc/jsonrpc
+ echo

+ rm -f /Users/ym/work/go1.4/pkg/tool/darwin_amd64/go_bootstrap
+ '[' '' '!=' --no-banner ']'
+ /Users/ym/work/go1.4/pkg/tool/darwin_amd64/dist banner

---
Installed Go for darwin/amd64 in /Users/ym/work/go1.4
Installed commands in /Users/ym/me/go/test/bin
```

我们看到15-33行, 首先编译了`cmd/dist`文件夹下的c代码，生成了一个dist可执行文件，并调用了 `/cmd/dist/dist env -p`
<pre>
<b># Building C bootstrap tool.</b>
+ echo cmd/dist
cmd/dist
++ cd ..
++ pwd
+ export GOROOT=/Users/ym/work/go1.4
+ GOROOT=/Users/ym/work/go1.4
+ GOROOT_FINAL=/Users/ym/work/go1.4
+ DEFGOROOT='-DGOROOT_FINAL="/Users/ym/work/go1.4"'
+ mflag=
+ case "$GOHOSTARCH" in
++ uname
+ '[' Darwin == Darwin ']'
+ mflag=' -mmacosx-version-min=10.6'
++ type -t gcc
++ type -t clang
+ '[' -z '' -a -z file -a -n file ']'
<b>+ gcc -mmacosx-version-min=10.6 -O2 -Wall -Werror -o cmd/dist/dist -Icmd/dist '-DGOROOT_FINAL="/Users/ym/work/go1.4"' cmd/dist/arm.c cmd/dist/buf.c cmd/dist/build.c cmd/dist/buildgc.c cmd/dist/buildgo.c cmd/dist/buildruntime.c cmd/dist/main.c cmd/dist/plan9.c cmd/dist/unix.c cmd/dist/windows.c 
++ ./cmd/dist/dist env -p</b>
</pre>

那么我们来看看怎么在CLion中调试`/cmd/dist/dist env -p`

## CLion调试cmd/dist ##

如果要用CLion直接打开cmd/dist文件夹，会提示创建cmake项目，但是我们想直接使用调试Makefile项目。
那么我们在cmd/dist目录下创建一个Makefile文件，内容如下

```
CFLAGS = -mmacosx-version-min=10.6 -g -Wall -Werror '-DGOROOT_FINAL="/Users/ym/work/go1.4"'
CC = gcc

SRC=arm.c buf.c build.c buildgc.c buildgo.c buildruntime.c main.c plan9.c unix.c windows.c
INCLUDE_DIR = ./


TARGET = dist

all: $(TARGET)

$(TARGET):
	$(CC) $(CFLAGS) -I$(INCLUDE_DIR) $(SRC) -o $@


clean:
	rm $(TARGET)

.PHONY: all clean
```

其实就是根据make.bash打印的gcc编译命令改写的。需要注意的是要增加`-g`选项，这样才能调试。

然后参考[Run/Debug Configuration: Makefile Application](https://www.jetbrains.com/help/clion/run-debug-configuration-makefile-application.html)

配置几个参数，核心要指定的就是Target和Executable文件 
![clion-debug-makefile-config](/images/clion-debug-makefile-config.png)

最后先clean，然后断点调试`unix.c`文件中的main入口函数。

![clion-makefile-debug-show](/images/clion-makefile-debug-show.png)

成功了。