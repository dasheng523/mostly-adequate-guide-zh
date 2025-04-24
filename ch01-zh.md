# 第 1 章：我们到底在做什么？

## 引言

大家好！我是 Franklin Frisby 教授。很高兴认识各位。我们将共度一段时光，因为我将教大家一些关于函数式编程（Functional Programming）的知识。关于我的介绍就到这里，那么你呢？我希望你至少对 JavaScript 语言有些熟悉，有一点点面向对象（Object-Oriented）的经验，并认为自己是一名实战派程序员。你不需要有昆虫学的博士学位，只需要知道如何找到并消灭一些 bug 就行。

我不会假设你之前有任何函数式编程的知识，因为我们都知道假设会带来什么后果。但我确实期望你曾遇到过一些因使用可变状态（mutable state）、无限制的副作用（side effects）和无原则的设计而导致的不利情况。既然我们已经正式认识了，那就开始吧。

本章的目的是让你体会一下我们编写函数式程序时所追求的是什么。为了能够理解后续章节，我们必须对什么使程序成为*函数式*的有所了解。否则，我们会发现自己只是在漫无目的地涂写，不惜一切代价地避免使用对象——这确实是一种笨拙的做法。我们需要一个清晰的靶心来投掷我们的代码，一个在波涛汹涌时指引方向的天体罗盘。

现在，有一些通用的编程原则——各种缩写词构成的信条，引导我们穿越任何应用程序的黑暗隧道：DRY（不要重复自己）、YAGNI（你不会需要它）、松耦合高内聚（loose coupling high cohesion）、最小意外原则（principle of least surprise）、单一职责（single responsibility）等等。


我不会冗长地列出所有我这些年听过的指导方针来让大家厌烦……关键在于，这些原则在函数式编程的环境下同样适用，尽管它们只是我们最终目标的切线。在进一步深入之前，我现在想让你体会的是我们敲击键盘时的意图；我们函数式的世外桃源。

<!--BREAK-->

## 短暂交锋

让我们从一点疯狂的尝试开始。这里有一个关于海鸥的应用。当鸟群合并（conjoin）时，它们会变成一个更大的鸟群；当它们繁殖（breed）时，它们的数量会增加为与它们一起繁殖的海鸥数量的乘积。请注意，这并非意在展示好的面向对象代码，它在这里是为了强调我们现代基于赋值的方法的危险性。请看：

```js
class Flock {
  constructor(n) {
    this.seagulls = n;
  }

  conjoin(other) {
    this.seagulls += other.seagulls;
    return this;
  }

  breed(other) {
    this.seagulls = this.seagulls * other.seagulls;
    return this;
  }
}

const flockA = new Flock(4);
const flockB = new Flock(2);
const flockC = new Flock(0);
const result = flockA
  .conjoin(flockC)
  .breed(flockB)
  .conjoin(flockA.breed(flockB))
  .seagulls;
// 32
```

究竟是谁会创造出如此骇人听闻的劣作？要跟踪其内部可变状态是极其困难的。而且，天哪，答案甚至是错误的！它本应是 `16`，但 `flockA` 在这个过程中被永久地改变了。可怜的 `flockA`。这是信息技术界的无政府状态！这是狂野的动物算术！

如果你不理解这个程序，没关系，我也不理解。这里要记住的关键点是，即使在如此小的示例中，状态和可变值也很难追踪。

让我们再试一次，这次使用更函数式的方法：

```js
const conjoin = (flockX, flockY) => flockX + flockY;
const breed = (flockX, flockY) => flockX * flockY;

const flockA = 4;
const flockB = 2;
const flockC = 0;
const result =
    conjoin(breed(flockB, conjoin(flockA, flockC)), breed(flockA, flockB));
// 16
```

嗯，这次我们得到了正确的答案。而且代码少了很多。函数的嵌套有点令人困惑……（我们将在第 5 章解决这个问题）。这好多了，但让我们再深入一点。实话实说是有好处的。如果我们更仔细地审视我们的自定义函数，我们会发现我们其实只是在处理简单的加法（`conjoin`）和乘法（`breed`）。

除了名字之外，这两个函数实际上没有任何特别之处。让我们将自定义函数重命名为 `multiply` 和 `add`，以揭示它们的真实身份。

```js
const add = (x, y) => x + y;
const multiply = (x, y) => x * y;

const flockA = 4;
const flockB = 2;
const flockC = 0;
const result =
    add(multiply(flockB, add(flockA, flockC)), multiply(flockA, flockB));
// 16
```
就这样，我们获得了古老的知识：

```js
// associative // 结合律
add(add(x, y), z) === add(x, add(y, z));

// commutative // 交换律
add(x, y) === add(y, x);

// identity // 恒等律
add(x, 0) === x;

// distributive // 分配律
multiply(x, add(y,z)) === add(multiply(x, y), multiply(x, z));
```

啊哈，这些可靠的旧数学定律应该会派上用场。如果你不能立刻想起它们，别担心。对我们很多人来说，距离学习这些算术定律已经有一段时间了。让我们看看是否可以用这些定律来简化我们的小海鸥程序。

```js
// Original line // 原始代码行
add(multiply(flockB, add(flockA, flockC)), multiply(flockA, flockB));

// Apply the identity property to remove the extra add // 应用恒等律移除多余的加法
// (add(flockA, flockC) == flockA) // (add(flockA, flockC) 等于 flockA)
add(multiply(flockB, flockA), multiply(flockA, flockB));

// Apply distributive property to achieve our result // 应用分配律得到我们的结果
multiply(flockB, add(flockA, flockA));
```

太棒了！除了调用函数本身，我们根本不需要编写任何自定义代码。为了完整起见，我们在这里包含了 `add` 和 `multiply` 的定义，但实际上没有必要编写它们——我们肯定可以从某个现有的库中获得 `add` 和 `multiply`。

你可能会想：“你这是在用稻草人谬误，故意举一个如此数学化的例子”。或者“真实的程序没有这么简单，不能用这种方式来推理。” 我选择这个例子是因为我们大多数人已经了解加法和乘法，所以很容易看出数学在这里对我们是多么有用。

别灰心——在本书中，我们将穿插一些范畴论（category theory）、集合论（set theory）和 Lambda 演算（lambda calculus），并编写真实世界的例子，以达到与我们的海鸥群示例相同的优雅简洁性和结果。你也不必是数学家。它会感觉自然而轻松，就像你使用“普通”框架或 API 一样。

听到我们可以按照上面函数式模拟的方式编写完整的、日常的应用程序，可能会让你感到惊讶。这些程序具有可靠的属性。这些程序简洁，却易于推理。这些程序不会每次都重新发明轮子。如果你是罪犯，无法无天是件好事，但在本书中，我们将承认并遵守数学定律。

我们将希望使用一个理论，其中每个部分都倾向于如此礼貌地组合在一起。我们将希望用通用的、可组合的片段来表示我们的特定问题，然后利用它们的属性为我们自私的利益服务。这比命令式编程（imperative programming）那种“一切皆可”的方法需要更多的纪律（我们将在本书后面讨论“命令式”的精确定义，但现在可以将其视为函数式编程之外的任何东西）。在一个有原则的、数学化的框架内工作所带来的回报将真正让你震惊。

我们已经看到了我们函数式编程北极星的一丝微光，但在我们真正开始旅程之前，还需要掌握一些具体的概念。

[第 02 章：一等公民函数](ch02-zh.md)