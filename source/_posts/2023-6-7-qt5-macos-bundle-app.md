---
title:  "Mac下基于CMake自动打包部署Qt5项目"
date: 2023-6-7
author: alenym@qq.com
tags: 
  - qt5
  - cmake
  - mac
  - bundle
katex: true 
mathjax: true
---

## Qt5项目打包部署 ##

Mac下打包部署Qt5项目可以参考[Qt for macOS - Deployment](https://doc.qt.io/qt-5/macos-deployment.html)。
这里采用cmake构建Qt5项目。

<!-- more -->

## CMake打包要点说明 ##

Mac下针对一个PicPicker的具体项目，说明CMake打包项目的要点:

1. 设置针对构建Qt项目的全局选项。
```cmake
# MOC（Meta-Object Compiler）是 Qt 框架中的一个工具，它用于在编译时生成元对象代码（meta-object code）。
set(CMAKE_AUTOMOC ON)  

# RCC（Resource Compiler）是 Qt 框架中的一个工具，它用于将应用程序所需的资源文件（如图像、音频、样式表等）编译成二进制文件，并将其嵌入到可执行文件中，以便在运行时使用。
set(CMAKE_AUTORCC ON)  

# UIC（User Interface Compiler）是 Qt 框架中的一个工具，它用于将 Qt Designer 设计的用户界面（UI）文件（.ui 文件）编译成 C++ 代码，以便在应用程序中使用。
set(CMAKE_AUTOUIC ON)  

# 将当前目录包含到查找头文件的路径中，以便在处理 *.ui 文件时能够正确地找到相关的头文件。
set(CMAKE_INCLUDE_CURRENT_DIR ON) 
```
2. find_package 命令用于查找指定的软件包，并加载该软件包所提供的一些变量和模块。
```cmake
find_package(Qt5 COMPONENTS
        Core
        Gui
        Widgets
        Xml
        REQUIRED)
```
3. QT5_ADD_RESOURCES 是 CMake 中用于将 Qt 资源文件（.qrc 文件）编译成 C++ 代码的命令。
```cmake
# MyResources 是生成的 C++ 代码的输出文件名，application.qrc 是要编译的 Qt 资源文件的路径和文件名
QT5_ADD_RESOURCES(MyResources application.qrc)
```
4. 应用图标icns打包设置和国际化的打包路径设置
```cmake 
# 这样会设置应用图标的文件名
set(MACOSX_BUNDLE_ICON_FILE AppIcon.icns)
# 把"${CMAKE_SOURCE_DIR}/AppIcon.icns"图标打包到"Resources/"路径下
set(app_icon_macos "${CMAKE_SOURCE_DIR}/AppIcon.icns")
set_source_files_properties(${app_icon_macos} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

# 把国际化的*.qm打包到"Resources/l10n"路径下（这里目录l10n可以修改）
set_source_files_properties(${l10n_files} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources/l10n")
```
5. 构建可执行二进制目标为PicPicker。
```cmake
add_executable(PicPicker
        ${SOURCES}
        ${MyResources}
        ${app_icon_macos}
        ${l10n_files}
        )

# 这里的设置会告诉cmake在生成目标文件PicPicker之后，创建PicPicker.app/Contents/目录结构，并把二进制复制到
# "PicPicker.app/Contents/MacOS/"路径下。因此PicPicker运行时读取资源文件的相对路径为"../Resources/"
set_target_properties(PicPicker PROPERTIES
        MACOSX_BUNDLE TRUE
        )

target_link_libraries(PicPicker
        Qt5::Core
        Qt5::Gui
        Qt5::Widgets
        Qt5::Xml
        )
```
6. 使用 macdeployqt 工具自动处理Qt库的依赖关系和相关文件，将应用程序打包成一个独立的、可执行的 macOS 应用程序包（.app 文件），以便在其他机器上运行。
```cmake
# 找到环境macdeployqt工具
get_target_property(_qmake_executable Qt5::qmake IMPORTED_LOCATION)
get_filename_component(_qt_bin_dir "${_qmake_executable}" DIRECTORY)
find_program(MACDEPLOYQT_EXECUTABLE macdeployqt HINTS "${_qt_bin_dir}")

# 添加自定义命令，执行的时间为PicPicker二进制构建完成。
add_custom_command(TARGET PicPicker POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_CURRENT_SOURCE_DIR}/AppIcon.icns"
        "$<TARGET_FILE_DIR:PicPicker>/../Resources/"
        COMMENT "Copy AppIcon.icns to Resources/"
        &&
        COMMAND "${MACDEPLOYQT_EXECUTABLE}"
        ARGS "PicPicker.app" "-dmg" "-always-overwrite" "-no-strip"
        COMMENT "Execute macdeployqt to create macOS bundle"
        )
```

**注意** 
 
`MACOSX_BUNDLE`设置为`TRUE`已经会把文件拷贝到相应的路径，而这里再做一遍是因为
POST_BUILD 事件的触发是PicPicker链接完成，而不是复制文件到PicPicker.app的目录下，
因此会造成当进行dmg打包的时候，图标文件还没有复制到目录下。日志如下：

```log
    [100%] Linking CXX executable PicPicker.app/Contents/MacOS/PicPicker
    Execute macdeployqt to create macOS bundle
    Copying OS X content PicPicker.app/Contents/Resources/AppIcon.icns
    [100%] Built target PicPicker
```

所以只能用此下策。使用cmake第二遍拷贝到`$<TARGET_FILE_DIR:PicPicker>/../Resources/`路径下。

PicPicker目标文件的路径是`PicPicker.app/MacOS/PicPicker`,因此`$<TARGET_FILE_DIR:PicPicker>`就是
`PicPicker.app/MacOS/`，所以`$<TARGET_FILE_DIR:PicPicker>/../Resources/`就是`PicPicker.app/Resources/`

## CMakeLists.txt完整内容 ##

仅供参考
```cmake 
cmake_minimum_required(VERSION 3.23)
project(picpicker)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
# for *.ui to include current dir to find headers.
set(CMAKE_INCLUDE_CURRENT_DIR ON)

find_package(Qt5 COMPONENTS
        Core
        Gui
        Widgets
        Xml
        REQUIRED)

set(SOURCES
        src/main.cpp
        src/mainwindow.cpp
        src/AppModel.cpp
        )

set(l10n_files
        )

QT5_ADD_RESOURCES(MyResources application.qrc)

set(MACOSX_BUNDLE_ICON_FILE AppIcon.icns)
set(app_icon_macos "${CMAKE_SOURCE_DIR}/AppIcon.icns")
set_source_files_properties(${app_icon_macos} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
set_source_files_properties(${l10n_files} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources/l10n")

add_executable(PicPicker
        ${SOURCES}
        ${MyResources}
        ${app_icon_macos}
        ${l10n_files}
        )

set_target_properties(PicPicker PROPERTIES
        MACOSX_BUNDLE TRUE
        )

target_link_libraries(PicPicker
        Qt5::Core
        Qt5::Gui
        Qt5::Widgets
        Qt5::Xml
        )

get_target_property(_qmake_executable Qt5::qmake IMPORTED_LOCATION)
get_filename_component(_qt_bin_dir "${_qmake_executable}" DIRECTORY)
find_program(MACDEPLOYQT_EXECUTABLE macdeployqt HINTS "${_qt_bin_dir}")

add_custom_command(TARGET PicPicker POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_CURRENT_SOURCE_DIR}/AppIcon.icns"
        "$<TARGET_FILE_DIR:PicPicker>/../Resources/"
        COMMENT "Copy AppIcon.icns to Resources/"
        &&
        COMMAND "${MACDEPLOYQT_EXECUTABLE}"
        ARGS "PicPicker.app" "-dmg" "-always-overwrite" "-no-strip"
        COMMENT "Execute macdeployqt to create macOS bundle"
        )
```

## 总结 ##

1. 因为没有使用QML，所以没有考虑打包QML文件的情况。
2. 只是在Mac平台下。
3. `-no-strip`参数在发布的时候要去掉，这里添加是为了开发时方便debug。
4. `-always-overwrite`参数也是为了方便，直接覆盖已经产生的dmg文件。

