---
title:  "使用Iced的过程中理解Rust的关联类型"
date: 2023-2-28
author: alenym@qq.com
tags: 
  - rust
  - iced
katex: true 
mathjax: true
---

## 关联类型(Associated type) ##

关联类型是Rust为了解决类型参数(type parameter)之间的依赖关系而引入的。清楚的解释引入动机的文章就是
[RFC095](https://github.com/rust-lang/rfcs/blob/master/text/0195-associated-items.md#motivation)
。
<!-- more -->

同时，这篇文章详细说明了如何[引用关联类型](https://github.com/rust-lang/rfcs/blob/master/text/0195-associated-items.md#motivation)。

## 一个实际的例子 ##

我们在使用[Iced](https://github.com/iced-rs/iced)（一个跨平台的GUI库）开发一个自定义样式的button的时候，
遇到了关联类型。

以下代码创建一个button对象，宽度80，高50，样式怎么输入呢？
```rust
button(
    text(input).size(24)
        .vertical_alignment(Vertical::Center)
        .horizontal_alignment(Horizontal::Center)
)
    .padding(10)
    .width(80)
    .height(50)
    .style( ?? )    /// <-- 这里该写什么呢？
    .on_press(msg)
```
看看这个style方法的签名。
```text
iced_native::widget::button 
impl<'a, Message, Renderer> Button<'a, Message, Renderer> 
where     
    Renderer: crate::Renderer,     
    Renderer::Theme: StyleSheet,
pub fn style(mut self, style: <Renderer::Theme as StyleSheet>::Style) -> Self
-------------------------------------------------------------
Sets the style variant of this Button.
```
style方法是Button结构体的一个关联方法。

Button结构体是一个组件，它有两个类型参数，Message和Renderer。
其中`Renderer`类型参数的Bound在where中明确
- Renderer: crate::Renderer   需要实现`crate::Renderer` trait.
- Renderer::Theme: StyleSheet 并且该`crate::Renderer` trait的`Theme`关联类型需要实现 `StyleSheet` trait.

`crate::Renderer` trait如下，有一个`Theme`关联类型
```rust
/// A component that can be used by widgets to draw themselves on a screen.
pub trait Renderer: Sized {
    /// The supported theme of the [`Renderer`].
    type Theme;
    ...
    ...
```

还是回到这个style方法`pub fn style(mut self, style: <Renderer::Theme as StyleSheet>::Style) -> Self`。

这个方法的入参style的类型是`<Renderer::Theme as StyleSheet>::Style`，这个PATH的前缀是
`<Renderer::Theme as StyleSheet>` 表示实现了Renderer trait的类型的`Theme`关联类型 
需要实现`StyleSheet` trait。

因此`<Renderer::Theme as StyleSheet>::Style`完整的含义就是 
1. 某个渲染类型 SomeRenderer 实现了`crate::Renderer` trait. 
2. 某个样式板类型 SomeThemeType 实现了`button::StyleSheet`。
3. 且 SomeRenderer::Theme = SomeThemeType
4. `<Renderer::Theme as StyleSheet>::Style`就是 SomeThemeType::Style = < ?? >.

因此style方法的入参的实际类型就是SomeStyleSheet::Style的实际类型。所以我们要找到SomeRenderer和SomeThemeType。

1. 先看`crate::Renderer` trait的实现类型有那些，可以看到`Renderer<B, T>`
```rust 
impl<B, T> iced_native::Renderer for Renderer<B, T>
where
    B: Backend,
{
    type Theme = T;
    ...
    ...
```

这个结构体如下，
```rust
/// A backend-agnostic renderer that supports all the built-in widgets.
#[derive(Debug)]
pub struct Renderer<B: Backend, Theme> {
    backend: B,
    primitives: Vec<Primitive>,
    theme: PhantomData<Theme>,
}
```
这个似乎就是我们要找的 SomeRenderer。但是这个`Renderer<B, T>`有两个类型参数，第二个就是Theme类型参数。还是没有看到
这个类型参数具体的类型是什么。继续看哪里使用了这个带有类型参数的结构体`Renderer<B, T>`。
```rust 
/// A [`wgpu`] graphics renderer for [`iced`].
///
/// [`wgpu`]: https://github.com/gfx-rs/wgpu-rs
/// [`iced`]: https://github.com/iced-rs/iced
pub type Renderer<Theme = iced_native::Theme> =
    iced_graphics::Renderer<Backend, Theme>;
```
这里看到声明了一个新的类型`iced_wgpu::Renderer`，并且指定了`Theme = iced_style::theme::Theme`。
这个新的类型在哪里使用了呢？
```rust 
impl<Theme> iced_graphics::window::Compositor for Compositor<Theme> {
    type Settings = Settings;
    type Renderer = Renderer<Theme>;
    type Surface = wgpu::Surface;

    fn new<W: HasRawWindowHandle + HasRawDisplayHandle>(
        settings: Self::Settings,
        compatible_window: Option<&W>,
    ) -> Result<(Self, Self::Renderer), Error> {
        let compositor = futures::executor::block_on(Self::request(
            settings,
            compatible_window,
        ))
        .ok_or(Error::GraphicsAdapterNotFound)?;

        let backend = compositor.create_backend();

        Ok((compositor, Renderer::new(backend)))  /// <--- 这里的Renderer就是指定了Theme的Renderer<B,T>
    }
```
因此这个`iced_wgpu::Renderer`就是我们要找的SomeRenderer，而SomeRenderer::Theme就是
`iced_style::theme::Theme`就是我们要找的SomeThemeType。

2. 接着看`iced_style::theme::Theme`类型如何实现`button::StyleSheet` trait
![button_stylesheet_for_theme](./images/20230228-button_style_for_theme.png)
从这里可以看到 `SomeThemeType::Style = iced_style::theme::Button`
因此style方法的入参是iced_style::theme::Button, 是一个枚举类型。

```rust
/// The style of a button.
#[derive(Default)]
pub enum Button {
    /// The primary style.
    #[default]
    Primary,
    /// The secondary style.
    Secondary,
    /// The positive style.
    Positive,
    /// The destructive style.
    Destructive,
    /// The text style.
    ///
    /// Useful for links!
    Text,
    /// A custom style.
    Custom(Box<dyn button::StyleSheet<Style = Theme>>),
} 
```
从定义可以看出，如果我们要实现自定义的样式就需要使用Button::Custom(Box::new(??)).

而`button::StyleSheet<Style = Theme>`类型意思是某类型实现了`button::StyleSheet` trait,
并且关联类型Style = iced_style::theme::Theme. 

所以我们可以写一个自定义的button样式了。
```rust 
struct ButtonStyle;

impl StyleSheet for ButtonStyle {
    type Style = iced_style::theme::Theme; ///<-- 这里可以简写为 type Style = Theme;

    fn active(&self, style: &Self::Style) -> Appearance {
        Appearance {
            shadow_offset: Default::default(),
            background: Some(Background::Color(Color::from_rgb8(204, 204, 204))),
            border_radius: 5.0,
            border_width: 0.0,
            border_color: Default::default(),
            text_color: Color::from_rgb8(0, 0, 0),
        }
    }
}
```
style方法的入参就是`Button::Custom(Box::new(ButtonStyle{}))`。

最后style方法的使用如下
```rust
button(
    text(input).size(24)
        .vertical_alignment(Vertical::Center)
        .horizontal_alignment(Horizontal::Center)
)
    .padding(10)
    .width(80)
    .height(50)
    .style( Button::Custom(Box::new(ButtonStyle{})) ) /// 这里该写什么呢？
    .on_press(msg)
```

## 关于Iced

`Iced`使用的Elm模型非常容易使用。我用它实现一个简单的计算器。
![calculator](./images/20230228-calculator.png)

## 总结
关联类型是Rust非常重要的特性。如果不深入理解的话，编译的错误信息都看不明白。