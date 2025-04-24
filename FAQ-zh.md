好的，这是 FAQ 部分的翻译：

## 常见问题解答 (FAQ)

- [为什么代码片段有时带分号有时不带？](#why-are-snippets-written-sometimes-with-semicolons-and-sometimes-without)
- [像 _ (ramda) 或 $ (jquery) 这样的外部库调用难道不会让函数变得不纯吗？](#arent-external-libraries-like-_-ramda-or--jquery-making-calls-impure)
- [类型签名中 `f a` 的含义是什么？](#what-is-the-meaning-of-f-a-in-signature)
- [有没有“真实世界”的例子？](#is-there-any-real-world-examples-available)
- [为什么本书使用 ES5？有 ES6 版本吗？](#why-does-the-book-uses-es5-is-any-es6-version-available)
- [那个 reduce 函数到底是怎么回事？](#what-the-heck-is-that-reduce-function-about)
- [您是否会使用更简化的英语而不是当前的风格？](#wouldnt-you-use-a-simplified-english-rather-than-the-current-style)
- [什么是 Either？什么是 Future？什么是 Task？](#what-is-either-what-is-future-what-is-task)
- [map, filter, compose ... 这些方法来自哪里？](#where-do-map-filter-compose--methods-come-from)

### 为什么代码片段有时带分号有时不带？

> 参见 [#6]

在 JavaScript 中有两个流派，使用分号的人和不使用分号的人。我们在这里选择了使用它们，现在，我们努力与这一选择保持一致。如果遗漏了一些，请告知我们，我们会处理这个疏忽。

### 像 _ (ramda) 或 $ (jquery) 这样的外部库调用难道不会让函数变得不纯吗？

> 参见 [#50]

这些依赖项可以被看作是全局上下文的一部分，是语言本身的一部分。所以，不，这些调用仍然可以被认为是纯的（pure）。
要进一步阅读，请查看[这篇关于 CoEffects 的文章](http://tomasp.net/blog/2014/why-coeffects-matter/)

### 类型签名中 `f a` 的含义是什么？

> 参见 [#62]

在一个类型签名（signature）中，例如：

`map :: Functor f => (a -> b) -> f a -> f b`

`f` 指的是一个`函子`（functor），例如，可以是 Maybe 或 IO。因此，该签名通过使用类型变量抽象了函子的选择，这基本上意味着任何函子都可以用在 `f` 的位置，只要所有的 `f` 都属于相同的类型（如果签名中的第一个 `f a` 代表一个 `Maybe a`，那么第二个 **不能指向** 一个 `IO b`，而应该是一个 `Maybe b`）。例如：

```javascript
let maybeString = Maybe.of("Patate")
let f = function (x) { return x.length }
let maybeNumber = map(f, maybeString) // Maybe(6)

// 对于下面这个“精确化”的签名：
// map :: (string -> number) -> Maybe string -> Maybe number
```

### 有没有“真实世界”的例子？

> 参见 [#77], [#192]

如果您还没有读到那里，可以看一下[第六章](https://github.com/MostlyAdequate/mostly-adequate-guide/blob/master/ch06.md)，其中介绍了一个简单的 Flickr 应用程序。
其他例子可能会在后面出现。顺便说一句，欢迎与我们分享您的经验！

### 为什么本书使用 ES5？有 ES6 版本吗？

> 参见 [#83], [#235]

本书旨在让更多人能够轻松阅读。它在 ES6 问世之前就开始编写了，现在，随着新标准的接受度越来越高，我们正在考虑制作两个独立的版本，分别使用 ES5 和 ES6。社区成员已经在进行 ES6 版本的工作（更多信息请参见 [#235]）。

### 那个 reduce 函数到底是怎么回事？

> 参见 [#109]

Reduce、accumulate、fold、inject 都是函数式编程中常用的函数，用于连续组合数据结构的元素。您可以观看[这个演讲](https://www.youtube.com/watch?v=JZSoPZUoR58&ab_channel=NewCircleTraining)以获取更多关于 reduce 函数的见解。

### 您是否会使用更简化的英语而不是当前的风格？

> 参见 [#176]

本书有其独特的写作风格，这有助于使其整体保持一致。如果您不熟悉英语，可以将其视为一次很好的练习。尽管如此，如果您有时需要帮助来理解含义，现在有[几个翻译版本](https://github.com/MostlyAdequate/mostly-adequate-guide/blob/master/TRANSLATIONS.md)可以帮助您。

### 什么是 Either？什么是 Future？什么是 Task？

> 参见 [#194]

我们在书中逐步介绍了所有这些结构。因此，您不会遇到任何事先未定义的结构的使用。如果您对这些类型感到不适，请不要犹豫，重新阅读前面的部分。
最后会有一个术语表/手册来综合所有这些概念。

### map, filter, compose ... 这些方法来自哪里？

> 参见 [#198]

大多数时候，这些方法是在特定的供应商库（如 `ramda` 或 `underscore`）中定义的。您也应该查看[附录 A](./appendix_a.md)、[附录 B](./appendix_b.md) 和 [附录 C](./appendix_c.md)，我们在其中为练习定义了几个实现。这些函数在函数式编程中非常常见，尽管它们的实现可能略有不同，但它们在不同库之间的含义相当一致。


[#6]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/6
[#50]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/50
[#62]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/62
[#77]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/77
[#83]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/83
[#109]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/109
[#176]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/176
[#192]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/192
[#194]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/194
[#198]: https://github.com/MostlyAdequate/mostly-adequate-guide/issues/198
[#235]: https://github.com/MostlyAdequate/mostly-adequate-guide/pull/235