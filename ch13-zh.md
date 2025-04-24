# 第 13 章：Monoid 将万物聚合

## 狂野的组合

在本章中，我们将通过 半群（Semigroup） 来考察 *Monoid*。*Monoid* 是数学抽象概念中粘在头发上的泡泡糖。它们捕捉了一个跨越多个学科的思想，形象地、也确实地将它们聚合在一起。它们是连接所有计算的神秘力量。是我们代码库中的氧气，是其运行的基础，是编码形式的量子纠缠。

*Monoid* 关乎组合。但什么是组合呢？它可以意味着很多事情，从累积到连接、到乘法、到选择、组合、排序，甚至求值！我们将在这里看到许多例子，但这仅仅是 Monoid 大山的冰山一角。实例众多，应用广泛。本章的目标是提供一个良好的直觉，以便你可以创建一些你自己的 *Monoid*。

## 抽象化加法

加法有一些有趣的特性，我想讨论一下。让我们戴上抽象的护目镜来看看它。

首先，它是一个二元运算（binary operation），即一个接收两个值并返回一个值的运算，并且所有这些值都在同一个集合内。

```js
// 一个二元运算
1 + 1 = 2
```

看到了吗？定义域中的两个值，陪域中的一个值，都属于同一个集合——在这里是数字。有人可能会说数字“在加法下是封闭的”，意思是无论将哪些数字扔进混合中，类型永远不会改变。这意味着我们可以链式调用该运算，因为结果始终是另一个数字：

```js
// 我们可以对任意数量的数字执行此操作
1 + 7 + 5 + 4 + ...
```

除此之外（这双关语真是“算”计好了...），我们还有 结合律（associativity），它赋予了我们随意组合运算的能力。顺便说一句，一个具有结合律的二元运算是并行计算的秘诀，因为我们可以分块并分发工作。

```js
// 结合律
(1 + 2) + 3 = 6
1 + (2 + 3) = 6
```

现在，不要把它和 交换律（commutativity） 混淆了，交换律允许我们重新排列顺序。虽然加法满足交换律，但我们目前对这个属性并不特别感兴趣——对于我们的抽象需求来说太具体了。

说起来，我们的抽象超类到底应该包含哪些属性呢？哪些特性是加法特有的，哪些可以被泛化？在这个层级结构中是否存在其他抽象，还是说它就是一整块？我们的数学先驱们在构思抽象代数（abstract algebra）中的接口时，就运用了这种思维方式。

碰巧的是，那些老派的抽象主义者在抽象加法时，最终确定了 群（Group） 的概念。一个 *Group* 拥有所有的花哨功能，包括负数的概念。在这里，我们只对那个具有结合律的二元运算符感兴趣，所以我们将选择不那么具体的接口 *Semigroup*。*Semigroup* 是一个带有 `concat` 方法的类型，该方法充当我们的结合性二元运算符。

让我们为加法实现它，并称之为 `Sum`：

```js
const Sum = x => ({
  x,
  concat: other => Sum(x + other.x)
})
```

注意，我们用某个其他的 `Sum` 进行 `concat` 操作，并且总是返回一个 `Sum`。

我在这里使用了对象工厂而不是我们通常的原型仪式，主要是因为 `Sum` 不是 *Pointed* 的，而且我们不想每次都输入 `new`。总之，下面是它的实际应用：

```js
Sum(1).concat(Sum(3)) // Sum(4)
Sum(4).concat(Sum(37)) // Sum(41)
```

就这样，我们可以面向接口编程，而不是面向实现。由于这个接口来自群论（group theory），它有几个世纪的文献作为支撑。免费文档！

现在，如前所述，`Sum` 既不是 *Pointed* 的，也不是 *Functor*。作为练习，请回顾一下定律，看看为什么。好吧，我直接告诉你：它只能持有一个数字，所以 `map` 在这里没有意义，因为我们无法将底层值转换为另一种类型。那将是一个非常有限的 `map`！

那么这有什么用呢？嗯，就像任何接口一样，我们可以替换我们的实例来实现不同的结果：

```js
const Product = x => ({ x, concat: other => Product(x * other.x) })

const Min = x => ({ x, concat: other => Min(x < other.x ? x : other.x) })

const Max = x => ({ x, concat: other => Max(x > other.x ? x : other.x) })
```

但这并不仅限于数字。让我们看看其他一些类型：

```js
const Any = x => ({ x, concat: other => Any(x || other.x) })
const All = x => ({ x, concat: other => All(x && other.x) })

Any(false).concat(Any(true)) // Any(true)
Any(false).concat(Any(false)) // Any(false)

All(false).concat(All(true)) // All(false)
All(true).concat(All(true)) // All(true)

[1,2].concat([3,4]) // [1,2,3,4]

"miracle grow".concat("n") // miracle grown"

Map({day: 'night'}).concat(Map({white: 'nikes'})) // Map({day: 'night', white: 'nikes'})
```

如果你盯着这些看足够久，模式就会像立体画一样跳出来。它无处不在。我们在合并数据结构，组合逻辑，构建字符串……似乎几乎任何任务都可以被强行塞进这个基于组合的接口中。

我已经用了几次 `Map` 了。如果你们俩之前没有被正式介绍，请原谅我。`Map` 只是简单地包装了 `Object`，这样我们就可以在不改变宇宙结构的情况下为其添加一些额外的方法。


## 我所有钟爱的 Functor 都是 Semigroup

我们目前看到的实现了 Functor 接口的类型，也都实现了 Semigroup 接口。让我们看看 `Identity`（以前称为 Container 的那位艺术家）：

```js
Identity.prototype.concat = function(other) {
  return new Identity(this.__value.concat(other.__value))
}

Identity.of(Sum(4)).concat(Identity.of(Sum(1))) // Identity(Sum(5))
Identity.of(4).concat(Identity.of(1)) // TypeError: this.__value.concat 不是一个函数
```

它是一个 *Semigroup* 当且仅当它的 `__value` 是一个 *Semigroup*。就像一个手滑的滑翔伞飞行员，它持有 Semigroup 时自身才是 Semigroup。

其他类型也有类似的行为：

```js
// 结合错误处理
Right(Sum(2)).concat(Right(Sum(3))) // Right(Sum(5))
Right(Sum(2)).concat(Left('some error')) // Left('some error')


// 异步结合
Task.of([1,2]).concat(Task.of([3,4])) // Task([1,2,3,4])
```

当我们将这些 Semigroup 堆叠成级联组合时，这就变得特别有用：

```js
// formValues :: Selector -> IO (Map String String)
// validate :: Map String String -> Either Error (Map String String)

formValues('#signup').map(validate).concat(formValues('#terms').map(validate)) // IO(Right(Map({username: 'andre3000', accepted: true})))
formValues('#signup').map(validate).concat(formValues('#terms').map(validate)) // IO(Left('one must accept our totalitarian agreement'))

serverA.get('/friends').concat(serverB.get('/friends')) // Task([friend1, friend2])

// loadSetting :: String -> Task Error (Maybe (Map String Boolean))
loadSetting('email').concat(loadSetting('general')) // Task(Maybe(Map({backgroundColor: true, autoSave: false})))
```

在第一个例子中，我们组合了一个持有 `Either`、`Either` 又持有 `Map` 的 `IO`，来验证和合并表单值。接下来，我们访问了几个不同的服务器，并使用 `Task` 和 `Array` 以异步方式组合了它们的结果。最后，我们堆叠了 `Task`、`Maybe` 和 `Map` 来加载、解析和合并多个设置。

这些可以通过 `chain` 或 `ap` 来实现，但 *Semigroup* 更简洁地捕捉了我们想要做的事情。

这不仅仅局限于 Functor。事实上，事实证明，任何完全由 Semigroup 组成的东西，其本身也是一个 Semigroup：如果我们能 `concat` 部件，那么我们就能 `concat` 整体。

```js
const Analytics = (clicks, path, idleTime) => ({
  clicks,
  path,
  idleTime,
  concat: other =>
    Analytics(clicks.concat(other.clicks), path.concat(other.path), idleTime.concat(other.idleTime))
})

Analytics(Sum(2), ['/home', '/about'], Right(Max(2000))).concat(Analytics(Sum(1), ['/contact'], Right(Max(1000))))
// Analytics(Sum(3), ['/home', '/about', '/contact'], Right(Max(2000)))
```

看，所有东西都知道如何很好地自我组合。事实证明，我们可以通过使用 `Map` 类型免费做到同样的事情：

```js
Map({clicks: Sum(2), path: ['/home', '/about'], idleTime: Right(Max(2000))}).concat(Map({clicks: Sum(1), path: ['/contact'], idleTime: Right(Max(1000))}))
// Map({clicks: Sum(3), path: ['/home', '/about', '/contact'], idleTime: Right(Max(2000))})
```

我们可以随心所欲地堆叠和组合任意数量的这些东西。这仅仅是在森林中再加一棵树的问题，或者根据你的代码库情况，是在森林大火中再添一把火。

默认的、直观的行为是组合类型所持有的东西，然而，在某些情况下，我们会忽略里面的内容，而组合容器本身。考虑像 `Stream` 这样的类型：

```js
const submitStream = Stream.fromEvent('click', $('#submit'))
const enterStream = filter(x => x.key === 'Enter', Stream.fromEvent('keydown', $('#myForm')))

submitStream.concat(enterStream).map(submitForm) // Stream()
```

我们可以通过将来自两者的事件捕获为一个新的流来组合事件流。或者，我们也可以通过坚持它们持有 Semigroup 来组合它们。事实上，每种类型都有许多可能的实例。考虑 `Task`，我们可以通过选择两者中较早或较晚的那个来组合它们。我们总是可以选择第一个 `Right` 而不是在遇到 `Left` 时短路，这具有忽略错误的效果。有一个名为 *Alternative* 的接口，它实现了一些这样的，嗯，替代实例，通常侧重于选择而不是级联组合。如果你需要这样的功能，值得研究一下。

## Monoid 的虚无

我们之前在抽象加法，但就像巴比伦人一样，我们缺乏零的概念（文中零次提到它）。

零充当 单位元（identity），意味着任何元素加上 `0`，都会返回该元素本身。从抽象的角度来看，将 `0` 视为一种中性或 *空* 元素会很有帮助。重要的是，它在我们二元运算的左侧和右侧都以相同的方式起作用：

```js
// 单位元
1 + 0 = 1
0 + 1 = 1
```

让我们称这个概念为 `empty`，并用它创建一个新的接口。像许多初创公司一样，我们将选择一个极其缺乏信息量、但方便谷歌搜索的名字：*Monoid*。*Monoid* 的配方是：取任意 *Semigroup*，并添加一个特殊的 *单位元*。我们将通过在类型本身上实现一个 `empty` 函数来实现这一点：

```js
Array.empty = () => []
String.empty = () => ""
Sum.empty = () => Sum(0)
Product.empty = () => Product(1)
Min.empty = () => Min(Infinity)
Max.empty = () => Max(-Infinity)
All.empty = () => All(true)
Any.empty = () => Any(false)
```

一个空的、单位元的值什么时候会有用呢？这就像问为什么零是有用的一样。就像什么都没问……

当我们一无所有时，我们可以指望谁？零。我们想要多少个 bug？零。它是我们对不安全代码的容忍度。一个新的开始。最终的价格标签。它可以摧毁路径上的一切，也可以在紧要关头拯救我们。一个金色的救生圈和一个绝望的深渊。

在代码方面，它们对应着合理的默认值：

```js
const settings = (prefix="", overrides=[], total=0) => ...

const settings = (prefix=String.empty(), overrides=Array.empty(), total=Sum.empty()) => ...
```

或者在我们一无所有时返回一个有用的值：

```js
sum([]) // 0
```

它们也是累加器的完美初始值……

## 折叠乾坤

恰好 `concat` 和 `empty` 完美地契合了 `reduce` 的前两个参数槽。我们实际上可以通过忽略 *empty* 值来 `reduce` 一个 *Semigroup* 数组，但正如你所见，这会导致一个危险的境地：

```js
// concat :: Semigroup s => s -> s -> s
const concat = x => y => x.concat(y)

[Sum(1), Sum(2)].reduce(concat) // Sum(3)

[].reduce(concat) // TypeError: 对空数组使用 reduce 且未提供初始值
```

砰！炸药爆炸了。就像马拉松比赛中扭伤了脚踝，我们遇到了一个运行时异常。JavaScript 非常乐意让在跑步前把手枪绑在运动鞋上——我想，它是一种保守的语言，但是当数组为空时，它会让我们戛然而止。它到底能返回什么呢？`NaN`、`false`、`-1`？如果我们要继续执行程序，我们希望得到一个正确类型的结果。它可以返回一个 `Maybe` 来表示失败的可能性，但我们可以做得更好。

让我们使用我们柯里化过的 `reduce` 函数，并制作一个安全的版本，其中 `empty` 值不是可选的。它从此将被称为 `fold`：

```js
// fold :: Monoid m => m -> [m] -> m
const fold = reduce(concat)
```

初始的 `m` 是我们的 `empty` 值——我们的中性起点，然后我们取一个 `m` 的数组，并将它们压成一个美丽的、钻石般的值。

```js
fold(Sum.empty(), [Sum(1), Sum(2)]) // Sum(3)
fold(Sum.empty(), []) // Sum(0)

fold(Any.empty(), [Any(false), Any(true)]) // Any(true)
fold(Any.empty(), []) // Any(false)


fold(Either.of(Max.empty()), [Right(Max(3)), Right(Max(21)), Right(Max(11))]) // Right(Max(21))
fold(Either.of(Max.empty()), [Right(Max(3)), Left('error retrieving value'), Right(Max(11))]) // Left('error retrieving value')

fold(IO.of([]), ['.link', 'a'].map($)) // IO([<a>, <button class="link"/>, <a>])
```

对于最后两个例子，我们手动提供了 `empty` 值，因为我们无法在类型本身上定义它。这完全没问题。类型化语言可以自己弄清楚，但在这里我们必须传入它。

## 不完全是 Monoid

有些 *Semigroup* 无法成为 *Monoid*，也就是说无法提供初始值。看看 `First`：

```js
const First = x => ({ x, concat: other => First(x) })

Map({id: First(123), isPaid: Any(true), points: Sum(13)}).concat(Map({id: First(2242), isPaid: Any(false), points: Sum(1)}))
// Map({id: First(123), isPaid: Any(true), points: Sum(14)})
```

我们将合并几个账户，并保留 `First` id。无法为其定义 `empty` 值。但这并不意味着它没有用。


## 宏大的统一理论

## 群论还是范畴论？

二元运算的概念在抽象代数中无处不在。事实上，它是一个 范畴（Category） 的主要运算。然而，没有 单位元（identity），我们就无法在范畴论（Category Theory）中模拟我们的运算。这就是为什么我们从群论中的 Semigroup 开始，然后在有了 *empty* 之后，跳转到范畴论中的 Monoid。

Monoid 形成一个单对象范畴，其中态射（morphism）是 `concat`，`empty` 是恒等态射（identity），并且组合（composition）是保证的。

### 作为 Monoid 的组合

类型为 `a -> a` 的函数，其定义域与陪域属于同一个集合，被称为 自同态（endomorphism）。我们可以创建一个名为 `Endo` 的 *Monoid* 来捕捉这个想法：

```js
const Endo = run => ({
  run,
  concat: other =>
    Endo(compose(run, other.run))
})

Endo.empty = () => Endo(identity)


// 实战一下

// thingDownFlipAndReverse :: Endo [String] -> [String]
const thingDownFlipAndReverse = fold(Endo(() => []), [Endo(reverse), Endo(sort), Endo(append('thing down')])

thingDownFlipAndReverse.run(['let me work it', 'is it worth it?'])
// ['thing down', 'let me work it', 'is it worth it?']
```

由于它们都是相同类型，我们可以通过 `compose` 进行 `concat`，并且类型总是能够对齐。

### 作为 Monoid 的 Monad

你可能已经注意到，`join` 是一个接收两个（嵌套的）Monad 并将它们以结合律的方式压扁成一个的操作。它也是一个 自然变换（natural transformation） 或“函子函数”。如前所述，我们可以创建一个以 Functor 为对象、以自然变换为态射的范畴。现在，如果我们将它特化为 *自函子*（Endofunctor），即相同类型的 Functor，那么 `join` 就为我们提供了自函子范畴中的 Monoid，也就是所谓的 Monad。要在代码中展示确切的公式需要一些技巧，我鼓励你去谷歌搜索，但这就是大致的概念。

### 作为 Monoid 的 Applicative

甚至 Applicative Functor 也有一个 Monoid 的形式化表述，在范畴论中被称为 *松散幺半群函子*（lax monoidal functor）。我们可以将接口实现为一个 Monoid，并从中恢复出 `ap`：

```js
// concat :: f a -> f b -> f [a, b]
// empty :: () -> f ()

// ap :: Functor f => f (a -> b) -> f a -> f b
const ap = compose(map(([f, x]) => f(x)), concat)
```


## 总结

所以你看，一切都是相互关联的，或者可以被关联起来。这个深刻的认识使得 *Monoid* 成为一个强大的建模工具，适用于从庞大的应用程序架构到最微小的数据片段。我鼓励你，无论何时直接的累积或组合是你应用程序的一部分时，都考虑使用 *Monoid*，然后，一旦你掌握了这一点，就开始将这个定义扩展到更多的应用中（你会惊讶地发现，用 *Monoid* 可以建模多少东西）。

## 练习