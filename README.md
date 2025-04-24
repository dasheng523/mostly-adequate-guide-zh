好的，这是 README 文件的翻译：

[![封面](images/cover.png)](SUMMARY.md)

## 关于本书

这是一本关于函数式范式（functional paradigm）的书。我们将使用世界上最流行的函数式编程语言：JavaScript。有些人可能会觉得这是一个糟糕的选择，因为它与当前主流的、感觉上主要是命令式（imperative）的文化背道而驰。然而，我相信基于以下几个原因，这是学习函数式编程（FP）的最佳方式：

 * **你很可能每天在工作中使用它。**

    这使得你能够每天在真实世界的程序中练习和应用所学知识，而不是在业余时间用某种深奥的函数式编程语言做一些个人项目（pet projects）。


 * **我们不必预先学习所有知识才能开始编写程序。**

    在纯函数式语言（pure functional language）中，不使用 Monad 就无法打印变量或读取 DOM 节点。在这里，我们可以稍微“作弊”一下，边学边净化我们的代码库。这门语言也更容易入门，因为它是混合范式的，你可以在知识存在差距时，回退到你当前的实践。


 * **这门语言完全有能力编写一流的函数式代码。**

    借助一两个小型库的帮助，我们拥有了模仿像 Scala 或 Haskell 这样的语言所需的所有特性。面向对象编程（Object-oriented programming）目前在业界占主导地位，但在 JavaScript 中显然很笨拙。这就像在高速公路旁露营，或者穿着雨鞋跳踢踏舞。我们不得不到处使用 `bind`，以免 `this` 在我们不注意时发生变化；我们有各种变通方法来处理忘记 `new` 关键字时的怪异行为；私有成员只能通过闭包（closures）来访问。对我们很多人来说，无论如何，函数式编程感觉更自然。

话虽如此，类型化的函数式语言（typed functional languages）无疑将是实践本书所展示风格的最佳场所。JavaScript 将是我们学习一种范式的途径，而你将其应用于何处则取决于你自己。幸运的是，这些接口是数学化的，因此无处不在。你会发现自己在 Swiftz、Scalaz、Haskell、PureScript 以及其他具有数学倾向的环境中如鱼得水。


## 在线阅读

为了获得最佳阅读体验，请[通过 Gitbook 在线阅读](https://mostly-adequate.gitbooks.io/mostly-adequate-guide/)。

- 快速访问侧边栏
- 浏览器内练习
- 深入的示例


## 动手实践代码

为了让学习更高效，并且在我讲述又一个故事时你不会太无聊，请确保动手实践本书中介绍的概念。有些概念起初可能难以掌握，通过亲自动手实践会更容易理解。
书中介绍的所有函数和代数数据结构都收集在附录中。相应的代码也可以作为一个 npm 模块使用：

```bash
$ npm i @mostly-adequate/support
```

此外，每个章节的练习都是可运行的，并且可以在你的编辑器中完成！例如，完成 `exercises/ch04` 中的 `exercise_*.js` 文件，然后运行：

```bash
$ npm run ch04
```

## 下载本书

在[最新发布版本](https://github.com/MostlyAdequate/mostly-adequate-guide/releases/latest)的构建产物（build artifacts）中查找预先生成的 **PDF** 和 **EPUB** 文件。

## 自己动手构建

> ⚠️ 这个项目的设置现在有点旧了，因此，在本地构建时你可能会遇到各种问题。如果可能，我们建议使用 node v10.22.1 和最新版本的 Calibre。

### 关于 nodejs 版本

由于推荐的 node 版本（v10.22.1）现在有点旧了，很可能你的系统上没有安装它。你可以使用 [nvm](https://github.com/nvm-sh/nvm) 在你的系统上安装多个 nodejs 版本。请参考该项目进行安装，然后你将能够：

 - 安装你需要的任何 node 版本：
```
nvm install 10.22.1
nvm install 20.2.0
```
 - 然后你将能够在 node 版本之间切换：
```
nvm use 10.22.1
node -v // 将显示 v10.22.1
nvm use 20.2.0
node -v // 将显示 v20.2.0
```

由于这个项目有一个 .nvmrc 文件，你可以直接调用 `nvm install` 和 `nvm use` 而无需指定 node 版本：
```
// 在此项目内的任何位置
nvm install
node -v // 将显示 v10.22.1
```


### 完整的命令序列

考虑到上述关于在系统上安装 nvm 的情况，以下是自行生成 pdf 和 epub 文件的完整命令序列：

```
git clone https://github.com/MostlyAdequate/mostly-adequate-guide.git
cd mostly-adequate-guide/
nvm install
npm install
npm run setup
npm run generate-pdf
npm run generate-epub
```

> 注意！要生成电子书版本，你需要安装 `ebook-convert`。[安装说明](https://gitbookio.gitbooks.io/documentation/content/build/ebookconvert.html)。

# 目录

参见 [SUMMARY.md](SUMMARY.md)

### 贡献

参见 [CONTRIBUTING.md](CONTRIBUTING.md)

### 翻译

参见 [TRANSLATIONS.md](TRANSLATIONS.md)

### 常见问题解答

参见 [FAQ.md](FAQ.md)



# 未来计划

*   **第一部分**（第 1-7 章）是基础知识指南。由于这是初稿，我会在发现错误时进行更新。欢迎帮助！
*   **第二部分**（第 8-13 章）讨论类型类（type classes），如 Functor 和 Monad，一直到 Traversable。我希望加入 Transformer 和一个纯应用（pure application）示例。
*   **第三部分**（第 14 章及以后）将开始在实用编程和学术荒诞之间跳舞。我们将探讨 Comonad、F-代数（f-algebras）、Free Monad、Yoneda 以及其他范畴学构造（categorical constructs）。


---


<p align="center">
  <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">
    <img alt="知识共享许可协议" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" />
  </a>
  <br />
  本作品采用<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">知识共享署名-相同方式共享 4.0 国际许可协议</a>进行许可。
</p>