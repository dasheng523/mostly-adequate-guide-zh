# 第七章：Hindley-Milner 和我

## 你的类型是什么？
如果你是函数式世界的新手，那么用不了多久你就会发现自己深陷类型签名（Type Signatures）之中。类型是一种元语言，它使得来自不同背景的人能够简洁而有效地沟通。在很大程度上，它们是用一种称为“Hindley-Milner”的系统编写的，我们将在本章一起探讨它。

在使用纯函数（pure functions）时，类型签名具有英语无法比拟的表达能力（expressive power）。这些签名会向你低语函数的私密信息。在简单紧凑的一行中，它们揭示了行为和意图。我们可以从中推导出“自由定理”（free theorems）。类型可以被推断（inferred），因此不需要显式的类型注解（type annotations）。它们可以被精确调整，也可以保持通用和抽象。它们不仅对编译时检查（compile time checks）有用，而且事实证明它们是最好的文档。因此，类型签名在函数式编程（functional programming）中扮演着重要角色——远比你最初想象的要重要得多。

JavaScript 是一门动态语言（dynamic language），但这并不意味着我们完全避免类型。我们仍然在处理字符串、数字、布尔值等等。只是语言层面没有任何集成，所以我们将这些信息记在脑子里。别担心，既然我们使用签名作为文档，我们可以使用注释来达到我们的目的。

JavaScript 有可用的类型检查工具，例如 [Flow](https://flow.org/) 或类型化的方言 [TypeScript](https://www.typescriptlang.org/)。本书的目标是为读者提供编写函数式代码的工具，因此我们将坚持使用函数式编程语言（FP languages）中通用的标准类型系统。


## 来自神秘代码（Cryptic）的故事

从尘封的数学书页，跨越浩瀚的白皮书海洋，在周六早晨的休闲博客文章中，深入到源代码本身，我们都能找到 Hindley-Milner 类型签名。这个系统非常简单，但需要快速解释一下并进行一些练习才能完全吸收这门小语言。

```js
// capitalize :: String -> String
const capitalize = s => toUpperCase(head(s)) + toLowerCase(tail(s));

capitalize('smurf'); // 'Smurf'
```

这里，`capitalize` 接收一个 `String` 并返回一个 `String`。不用管实现，我们感兴趣的是类型签名。

在 HM（Hindley-Milner）中，函数被写作 `a -> b`，其中 `a` 和 `b` 是任意类型的变量。所以 `capitalize` 的签名可以读作“一个从 `String` 到 `String` 的函数”。换句话说，它接收一个 `String` 作为输入，并返回一个 `String` 作为输出。

让我们看更多函数签名：

```js
// strLength :: String -> Number
const strLength = s => s.length;

// join :: String -> [String] -> String
const join = curry((what, xs) => xs.join(what));

// match :: Regex -> String -> [String]
const match = curry((reg, s) => s.match(reg));

// replace :: Regex -> String -> String -> String
const replace = curry((reg, sub, s) => s.replace(reg, sub));
```

`strLength` 的思路和之前一样：我们接收一个 `String` 并返回一个 `Number`。

其他的乍一看可能会让你困惑。即使不完全理解细节，你也可以总是将最后一个类型视为返回值。所以对于 `match`，你可以解释为：它接收一个 `Regex`（正则表达式）和一个 `String`，然后返回给你 `[String]`（字符串数组）。但这里发生了一件有趣的事情，如果可以的话，我想花点时间解释一下。

对于 `match`，我们可以自由地像这样对签名进行分组：

```js
// match :: Regex -> (String -> [String])
const match = curry((reg, s) => s.match(reg));
```

啊哈，将最后一部分用括号括起来揭示了更多信息。现在它被看作是一个接收 `Regex` 并返回给我们一个从 `String` 到 `[String]` 的函数。由于柯里化（currying），情况确实如此：给它一个 `Regex`，我们会得到一个函数，等待它的 `String` 参数。当然，我们不必这样想，但理解为什么最后一个类型是返回的类型是好的。

```js
// match :: Regex -> (String -> [String])
// onHoliday :: String -> [String]
const onHoliday = match(/holiday/ig);
```

每个参数会从签名的前面“弹出”一个类型。`onHoliday` 是已经接收了 `Regex` 参数的 `match` 函数。

```js
// replace :: Regex -> (String -> (String -> String))
const replace = curry((reg, sub, s) => s.replace(reg, sub));
```

正如你在 `replace` 的完整括号版本中所看到的，额外的符号会变得有点啰嗦和冗余，所以我们干脆省略它们。如果我们选择一次性给出所有参数，那么更容易将其视为：`replace` 接收一个 `Regex`、一个 `String`、另一个 `String`，然后返回给你一个 `String`。

最后几点：


```js
// id :: a -> a
const id = x => x;

// map :: (a -> b) -> [a] -> [b]
const map = curry((f, xs) => xs.map(f));
```

`id` 函数接收任意类型 `a` 并返回相同类型 `a` 的东西。我们能够在类型中使用变量，就像在代码中一样。像 `a` 和 `b` 这样的变量名是约定俗成的，但它们是任意的，可以用你喜欢的任何名称替换。如果它们是同一个变量，它们必须是相同的类型。这是一个重要的规则，所以让我们重申一下：`a -> b` 可以是任意类型 `a` 到任意类型 `b`，但 `a -> a` 意味着它们必须是相同的类型。例如，`id` 可以是 `String -> String` 或 `Number -> Number`，但不能是 `String -> Bool`。

`map` 类似地使用类型变量，但这次我们引入了 `b`，它可能与 `a` 是相同类型，也可能不是。我们可以这样解读它：`map` 接收一个从任意类型 `a` 到相同或不同类型 `b` 的函数，然后接收一个 `a` 的数组，并产生一个 `b` 的数组。

希望你已经被这个类型签名的表达之美所折服。它几乎逐字逐句地告诉我们函数的作用。它接收一个从 `a` 到 `b` 的函数，一个 `a` 的数组，然后它提供给我们一个 `b` 的数组。它唯一明智的做法就是在每个 `a` 上调用那个该死的（bloody）函数。任何其他做法都是弥天大谎。

能够推理类型及其含义是一项在函数式世界中会让你走得很远的技能。不仅论文、博客、文档等会变得更容易理解，而且签名本身几乎会向你讲解其功能。成为一个熟练的读者需要练习，但如果你坚持下去，大量的信息将无需阅读该死的手册（RTFMing）即可获得。

这里还有几个例子，看看你是否能自己解读它们。

```js
// head :: [a] -> a
const head = xs => xs[0];

// filter :: (a -> Bool) -> [a] -> [a]
const filter = curry((f, xs) => xs.filter(f));

// reduce :: ((b, a) -> b) -> b -> [a] -> b
const reduce = curry((f, x, xs) => xs.reduce(f, x));
```

`reduce` 也许是所有签名中最具表现力的。然而，它是一个棘手的家伙，所以如果你搞不定它，不要感到能力不足。对于好奇的人，我会尝试用英语解释，尽管自己研究签名会更有启发性。

咳咳，开始了……看着签名，我们看到第一个参数是一个函数，它期望接收 `b` 和 `a`，并产生一个 `b`。它从哪里得到这些 `a` 和 `b` 呢？嗯，签名中的后续参数是一个 `b` 和一个 `a` 的数组，所以我们只能假设那个 `b` 和那些 `a` 中的每一个都会被传入。我们还看到函数的结果是一个 `b`，所以这里的想法是我们对传入函数的最终调用将是我们的输出值。了解 reduce 的作用后，我们可以说上述分析是准确的。


## 缩小可能性

一旦引入了类型变量，就会出现一个奇特的属性，称为*参数化特性*（parametricity）。这个属性指出，一个函数将*以统一的方式作用于所有类型*。让我们研究一下：

```js
// head :: [a] -> a
```

看看 `head`，我们看到它将 `[a]` 映射到 `a`。除了具体类型 `array`（数组），它没有其他可用信息，因此，其功能仅限于操作数组本身。如果它对变量 `a` 一无所知，它可能用 `a` 做什么呢？换句话说，`a` 表示它不能是*特定*类型，这意味着它可以是*任何*类型，这使得我们得到的函数必须对*每个*可能的类型都统一地工作。这就是*参数化特性*的全部意义。猜测其实现，唯一合理的假设是它获取该数组的第一个、最后一个或一个随机元素。`head` 这个名字应该会给我们提示。

再看一个：

```js
// reverse :: [a] -> [a]
```

仅从类型签名来看，`reverse` 可能在做什么呢？同样，它不能对 `a` 做任何特定的事情。它不能将 `a` 更改为不同的类型，否则我们会引入一个 `b`。它能排序吗？嗯，不能，它没有足够的信息来对所有可能的类型进行排序。它能重新排列吗？是的，我想它可以做到，但它必须以完全相同且可预测的方式进行。另一种可能性是它可能决定移除或复制一个元素。无论如何，重点是，其可能的行为被其多态类型（polymorphic type）大大缩小了。

这种可能性的缩小使得我们可以使用像 [Hoogle](https://hoogle.haskell.org/) 这样的类型签名搜索引擎来查找我们想要的函数。紧密打包在签名中的信息确实非常强大。

## 定理之自由（Free）

除了推断实现的可能性，这种推理方式还能为我们带来*自由定理*（free theorems）。以下是从 [Wadler 关于该主题的论文](http://ttic.uchicago.edu/~dreyer/course/papers/wadler.pdf) 中直接摘录的几个随机示例定理。

```js
// head :: [a] -> a
compose(f, head) === compose(head, map(f));

// filter :: (a -> Bool) -> [a] -> [a]
compose(map(f), filter(compose(p, f))) === compose(filter(p), map(f));
```


你不需要任何代码来得到这些定理，它们直接从类型推导出来。第一个定理说，如果我们先获取数组的 `head`，然后对其运行某个函数 `f`，这等价于（顺便说一下，也快得多）我们先对每个元素 `map(f)`，然后取结果的 `head`。

你可能会想，嗯，这只是常识。但我上次检查时，计算机没有常识。确实，它们必须有一种形式化的方式来自动化这类代码优化。数学有一种将直觉形式化的方法，这在计算机逻辑的僵硬领域中很有帮助。

`filter` 定理是类似的。它说，如果我们组合 `f` 和 `p` 来检查哪些应该被过滤，然后通过 `map` 实际应用 `f`（记住 `filter` 不会转换元素——它的签名强制规定 `a` 不会被触及），这总是等价于先映射我们的 `f`，然后用 `p` 谓词过滤结果。

这些只是两个例子，但你可以将这种推理应用于任何多态类型签名，它将始终成立。在 JavaScript 中，有一些可用的工具来声明重写规则。也可以通过 `compose` 函数本身来做到这一点。这是唾手可得的成果，可能性是无穷的。

## 约束

最后要注意的一件事是，我们可以将类型约束（constrain）到一个接口（interface）。

```js
// sort :: Ord a => [a] -> [a]
```

我们在这里的胖箭头（`=>`）左边看到的是一个事实陈述：`a` 必须是 `Ord` 类型。或者换句话说，`a` 必须实现 `Ord` 接口。`Ord` 是什么，它从哪里来？在类型化语言中，它会是一个已定义的接口，说明我们可以对值进行排序。这不仅告诉我们更多关于 `a` 以及我们的 `sort` 函数在做什么，而且还限制了定义域（domain）。我们称这些接口声明为*类型约束*（type constraints）。

```js
// assertEqual :: (Eq a, Show a) => a -> a -> Assertion
```

这里，我们有两个约束：`Eq` 和 `Show`。它们将确保我们可以检查我们的 `a` 的相等性，并在它们不相等时打印差异。

我们将在后面的章节中看到更多约束的例子，这个概念应该会更加清晰。

## 总结

Hindley-Milner 类型签名在函数式世界中无处不在。虽然它们读写起来很简单，但要掌握仅通过签名理解程序的技巧需要时间。从现在开始，我们将为每一行代码添加类型签名。

[第八章：容器（Tupperware）](ch08-zh.md)