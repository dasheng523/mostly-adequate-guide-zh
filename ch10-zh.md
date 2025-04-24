# 第十章：Applicative 函子

## 应用 Applicative

**应用函子**（Applicative Functor）这个名字，鉴于其函数式起源，算是描述得相当好了。函数式程序员以想出像 `mappend` 或 `liftA4` 这样的名字而臭名昭著，这些名字在数学实验室里看起来完全自然，但在任何其他语境下，其清晰度就像一个在汽车穿梭餐厅（drive thru）点餐时犹豫不决的达斯·维达（Darth Vader）。

无论如何，这个名字应该已经泄露了这个接口（interface）给我们的东西：*将函子（functors）相互应用的能力*。

那么，像你这样正常、理性的人为什么会想要这样的东西呢？将一个函子应用于另一个函子到底*意味着*什么？

为了回答这些问题，我们将从你在函数式旅程中可能已经遇到的情况开始。假设，我们有两个函子（相同类型），我们想用它们的值作为参数来调用一个函数。比如一些简单的事情，像将两个 `Container` 的值相加。

```js
// 我们不能这样做，因为数字被装在瓶子里了。
add(Container.of(2), Container.of(3));
// NaN

// 让我们使用我们可靠的 map
const containerOfAdd2 = map(add, Container.of(2));
// Container(add(2)) // 得到一个包含部分应用函数的容器
```

我们得到了一个内部包含部分应用（partially applied）函数的 `Container`。更具体地说，我们有一个 `Container(add(2))`，我们想将其中的 `add(2)` 应用于 `Container(3)` 中的 `3` 来完成调用。换句话说，我们想将一个函子应用于另一个函子。

现在，碰巧我们已经有了完成这项任务的工具。我们可以 `chain`，然后 `map` 部分应用的 `add(2)`，就像这样：

```js
Container.of(2).chain(two => Container.of(3).map(add(two)));
// Container(5) // 译者注：原代码有误，链式调用后应为 Container(5)
```

这里的问题是，我们被困在了 Monad 的顺序世界中，在其中，任何事情都必须等到前一个 Monad 完成其工作后才能被求值。我们有两个强大的、独立的值，我认为仅仅为了满足 Monad 的顺序要求而延迟创建 `Container(3)` 是不必要的。

事实上，如果我们发现自己陷入这种困境（pickle jar），能够简洁地将一个函子的内容应用于另一个函子的值，而不需要这些不必要的函数和变量，那将是非常好的。


## 瓶中船

<img src="images/ship_in_a_bottle.jpg" alt="瓶中船 - https://www.deviantart.com/hollycarden" />

`ap` 是一个可以将一个函子中的函数内容应用于另一个函子中的值内容的函数。快速说五遍试试。

```js
Container.of(add(2)).ap(Container.of(3)); // 将 Container(add(2)) 应用于 Container(3)
// Container(5)

// 现在一起写

Container.of(2).map(add).ap(Container.of(3)); // 先 map(add) 得到 Container(add(2))，再 ap
// Container(5)
```

好了，干净利落。对 `Container(3)` 来说是个好消息，因为它从嵌套的 Monadic 函数的监狱中被释放了。值得再次提及的是，在这种情况下，`add` 在第一个 `map` 期间被部分应用了，所以这只有在 `add` 被柯里化（curried）时才有效。

我们可以这样定义 `ap`：

```js
Container.prototype.ap = function (otherContainer) {
  // 使用 otherContainer 的 map 方法来应用 this.$value (一个函数)
  return otherContainer.map(this.$value);
};
```

记住，`this.$value` 将是一个函数，我们将接受另一个函子，所以我们只需要 `map` 它。这样我们就有了我们的接口定义：


> *Applicative 函子*（Applicative functor）是带有 `ap` 方法的 Pointed 函子（pointed functor）。

注意对 **Pointed** 的依赖。Pointed 接口在这里至关重要，正如我们将在接下来的例子中看到的。

现在，我感觉到了你的怀疑（或者也许是困惑和恐惧），但请保持开放的心态；这个 `ap` 角色将被证明是有用的。在我们深入探讨之前，让我们探索一个不错的属性。

```js
F.of(x).map(f) === F.of(f).ap(F.of(x));
```

用恰当的英语来说，映射 `f` 等同于将一个包含 `f` 的函子 `ap` 到一个包含 `x` 的函子。或者用更恰当的英语来说，我们可以将 `x` 放入我们的容器并 `map(f)`，或者我们可以将 `f` 和 `x` 都提升（lift）到我们的容器中并对它们进行 `ap`。这允许我们以从左到右的方式编写：

```js
Maybe.of(add).ap(Maybe.of(2)).ap(Maybe.of(3)); // 将 Maybe(add) 应用于 Maybe(2)，再应用于 Maybe(3)
// Maybe(5)

Task.of(add).ap(Task.of(2)).ap(Task.of(3)); // 将 Task(add) 应用于 Task(2)，再应用于 Task(3)
// Task(5) // 概念上的结果
```

如果眯着眼看，人们甚至可能认出普通函数调用的模糊形状。我们将在本章后面讨论 pointfree 版本，但目前，这是编写此类代码的首选方式。使用 `of`，每个值都被传送到容器的神奇国度，这个平行宇宙中每次应用都可以是异步的或为空或任何情况，而 `ap` 将在这个奇幻的地方内应用函数。这就像在瓶子里造船。

你看到了吗？我们在例子中使用了 `Task`。这是一个 Applicative 函子发挥其作用的典型情况。让我们看一个更深入的例子。

## 协作的动机

假设我们正在构建一个旅游网站，我们想同时检索旅游目的地列表和当地活动列表。这两个都是独立的、自成一体的 API 调用。

```js
// Http.get :: String -> Task Error HTML // 假设的 HTTP GET 函数

// curry 确保 renderPage 会等待所有参数
const renderPage = curry((destinations, events) => { /* 渲染页面 */ });

// 使用 Task.of 和 ap 并行发起请求
Task.of(renderPage).ap(Http.get('/destinations')).ap(Http.get('/events'));
// Task("<div>some page with dest and events</div>") // 概念上的结果
```

两个 `Http` 调用都将立即发生，`renderPage` 将在两者都解决（resolved）后被调用。将此与 Monadic 版本进行对比，后者必须等待一个 `Task` 完成后下一个才能启动。因为我们不需要目的地信息来检索事件，所以我们摆脱了顺序求值。

再次强调，因为我们使用部分应用来实现这个结果，我们必须确保 `renderPage` 是柯里化的，否则它不会等待两个 `Task` 都完成。顺便说一句，如果你曾经手动做过这样的事情，你会欣赏这个接口惊人的简单性。这是那种将我们向奇点（singularity）又推近一步的漂亮代码。

让我们看另一个例子。

```js
// $ :: String -> IO DOM
const $ = selector => new IO(() => document.querySelector(selector)); // 获取 DOM 元素的 IO

// getVal :: String -> IO String
const getVal = compose(map(prop('value')), $); // 获取输入框值的 IO

// signIn :: String -> String -> Bool -> User
const signIn = curry((username, password, rememberMe) => { /* 登录中... */ }); // 柯里化的登录函数

// 使用 IO.of 和 ap 将多个 IO 操作的结果应用于 signIn 函数
IO.of(signIn).ap(getVal('#email')).ap(getVal('#password')).ap(IO.of(false)); // 将 rememberMe 包装在 IO.of 中
// IO({ id: 3, email: 'gg@allin.com' }) // 概念上的结果
```

`signIn` 是一个柯里化的 3 参数函数，所以我们必须相应地进行 `ap`。每次 `ap`，`signIn` 接收一个参数，直到它完成并运行。我们可以根据需要对任意数量的参数继续这种模式。另一件需要注意的事情是，有两个参数自然地出现在 `IO` 中，而最后一个参数需要 `of` 的一点帮助才能将其提升到 `IO` 中，因为 `ap` 期望函数及其所有参数都在同一类型中。

## 哥们，你到底能不能 Lift？

让我们研究一种 pointfree 的方式来编写这些 applicative 调用。既然我们知道 `map` 等于 `of/ap`，我们可以编写通用函数，它们将根据我们指定的次数进行 `ap`：

```js
// liftA2 :: Apply f => (a -> b -> c) -> f a -> f b -> f c
const liftA2 = curry((g, f1, f2) => f1.map(g).ap(f2));

// liftA3 :: Apply f => (a -> b -> c -> d) -> f a -> f b -> f c -> f d
const liftA3 = curry((g, f1, f2, f3) => f1.map(g).ap(f2).ap(f3));

// liftA4, 等等
```

`liftA2` 是个奇怪的名字。听起来像某个破旧工厂里挑剔的货运电梯，或者廉价豪华轿车公司的个性车牌。然而，一旦开悟，它就不言自明了：将这些部分提升（lift）到 applicative 函子的世界中。

当我第一次看到这种 2-3-4 的无聊东西时，我觉得它既丑陋又不必要。毕竟，我们可以在 JavaScript 中检查函数的参数数量（arity）并动态地构建它。然而，通常需要部分应用 `liftA(N)` 本身，所以它的参数长度不能变化。

让我们看看它的用法：

```js
// checkEmail :: User -> Either String Email // 检查 Email，返回 Either
// checkName :: User -> Either String String // 检查 Name，返回 Either

const user = {
  name: 'John Doe',
  email: 'blurp_blurp', // 无效的 Email
};

//  createUser :: Email -> String -> IO User // 假设的创建用户函数
const createUser = curry((email, name) => IO.of({ email, name })); // 简化版

// 使用 of 和 ap
Either.of(createUser).ap(checkEmail(user)).ap(checkName(user));
// Left('invalid email') // 因为 checkEmail 失败

// 使用 liftA2，结果相同，但更通用
liftA2(createUser, checkEmail(user), checkName(user));
// Left('invalid email')
```

因为 `createUser` 接收两个参数，我们使用相应的 `liftA2`。这两个语句是等价的，但 `liftA2` 版本没有提及 `Either`。这使得它更通用、更灵活，因为我们不再与特定类型绑定。


让我们看看之前用这种方式写的例子：

```js
liftA2(add, Maybe.of(2), Maybe.of(3));
// Maybe(5)

liftA2(renderPage, Http.get('/destinations'), Http.get('/events'));
// Task('<div>some page with dest and events</div>') // 概念上的结果

liftA3(signIn, getVal('#email'), getVal('#password'), IO.of(false));
// IO({ id: 3, email: 'gg@allin.com' }) // 概念上的结果
```


## 操作符

在像 Haskell、Scala、PureScript 和 Swift 这样的语言中，可以创建自己的中缀操作符（infix operators），你可能会看到这样的语法：

```hs
-- Haskell / PureScript
-- <$> 是 map, <*> 是 ap
add <$> Right 2 <*> Right 3
-- Right 5
```

```js
// JavaScript 等价写法
map(add, Right(2)).ap(Right(3));
// Right(5)
```

知道 `<$>` 是 `map`（也叫 `fmap`）而 `<*>` 只是 `ap` 是有帮助的。这允许更自然的函数应用风格，并可以帮助减少一些括号。

## 免费开罐器
<img src="images/canopener.jpg" alt="开罐器 - http://www.breannabeckmeyer.com/" />

我们还没有过多地讨论派生函数（derived functions）。鉴于所有这些接口都是相互构建的，并遵守一套定律，我们可以根据更强的接口来定义一些较弱的接口。

例如，我们知道 applicative 首先是一个 functor，所以如果我们有一个 applicative 实例，我们当然可以为我们的类型定义一个 functor。

这种完美的计算和谐是可能的，因为我们在一个数学框架内工作。即使莫扎特（Mozart）小时候用BT下载了 Ableton，他也做不到更好。

我之前提到 `of/ap` 等价于 `map`。我们可以利用这个知识免费定义 `map`：

```js
// 从 of/ap 派生 map
X.prototype.map = function map(f) {
  // 先将函数 f 放入容器，然后 ap 到当前容器 this 上
  return this.constructor.of(f).ap(this);
};
```

Monad 可以说是处于食物链的顶端，所以如果我们有 `chain`，我们可以免费获得 functor 和 applicative：

```js
// 从 chain 派生 map
X.prototype.map = function map(f) {
  // chain 一个函数，该函数应用 f 并用 of 将结果重新放入容器
  return this.chain(a => this.constructor.of(f(a)));
};

// 从 chain/map 派生 ap
X.prototype.ap = function ap(other) {
  // chain 一个函数 f (来自当前 monad)，然后将其 map 到 other monad 上
  return this.chain(f => other.map(f));
};
```

如果我们能定义一个 monad，我们就能定义 applicative 和 functor 接口。这非常了不起，因为我们免费得到了所有这些开罐器。我们甚至可以检查一个类型并自动化这个过程。

需要指出的是，`ap` 的部分吸引力在于能够并发运行事物，所以通过 `chain` 定义它会错过这种优化。尽管如此，在找到最佳实现方案的同时，拥有一个立即可用的接口是件好事。

你可能会问，为什么不直接使用 monad 就完事了？一个好的实践是使用你所需要的力量级别，不多也不少。这通过排除可能的功能将认知负荷降到最低。因此，倾向于使用 applicative 而不是 monad 是好的。

Monad 具有序列化计算、赋值变量和停止进一步执行的独特能力，这都归功于向下的嵌套结构。当人们看到 applicative 在使用时，他们不必关心任何这些事情。

现在，关于合法性...

## 定律

像我们探索过的其他数学构造一样，applicative 函子拥​​有一些有用的属性，供我们在日常代码中依赖。首先，你应该知道 applicative 是“在组合下封闭的”（closed under composition），这意味着 `ap` 永远不会改变我们的容器类型（这是倾向于使用它而不是 monad 的另一个原因）。这并不是说我们不能有多种不同的效果——我们可以堆叠我们的类型，知道它们在整个应用程序期间将保持不变。

为了演示：

```js
// 创建一个组合类型 Task(Maybe(x))
const tOfM = compose(Task.of, Maybe.of);

// 在组合类型上使用 liftA2 两次
liftA2(liftA2(concat), tOfM('Rainy Days and Mondays'), tOfM(' always get me down'));
// Task(Maybe(Rainy Days and Mondays always get me down)) // 类型保持不变
```

看，无需担心不同类型混入其中。

是时候看看我们最喜欢的范畴定律了：*同一律*（identity）：

### 同一律 (Identity)

```js
// identity
A.of(id).ap(v) === v;
```

是的，从函子内部应用 `id` 不应该改变 `v` 中的值。例如：

```js
const v = Identity.of('Pillow Pets');
Identity.of(id).ap(v) === v; // 应用 Identity(id) 不改变 v
```

`Identity.of(id)` 让我想笑它的徒劳。无论如何，有趣的是，正如我们已经确立的，`of/ap` 等同于 `map`，所以这个定律直接源于函子同一律：`map(id) == id`。

使用这些定律的美妙之处在于，就像一个好斗的幼儿园体育教练一样，它们迫使我们所有的接口都能很好地协同工作。

### 同态 (Homomorphism)

```js
// homomorphism
A.of(f).ap(A.of(x)) === A.of(f(x));
```

*同态*（homomorphism）只是一个保持结构的映射。事实上，函子只是范畴之间的*同态*，因为它在映射下保留了原始范畴的结构。


我们实际上只是将我们普通的函数和值塞进一个容器里，并在那里运行计算，所以如果我们最终得到相同的结果，无论是在容器内应用整个过程（等式左侧）还是在外部应用然后将其放入容器（等式右侧），这应该不足为奇。

一个快速的例子：

```js
// 在 Either 内部应用 vs 先应用再放入 Either
Either.of(toUpperCase).ap(Either.of('oreos')) === Either.of(toUpperCase('oreos'));
// Right('OREOS') === Right('OREOS')
```

### 交换律 (Interchange)

*交换律*（interchange）定律指出，我们选择将函数提升到 `ap` 的左侧还是右侧并不重要。

```js
// interchange
v.ap(A.of(x)) === A.of(f => f(x)).ap(v);
```

这是一个例子：

```js
const v = Task.of(reverse); // Task(reverse)
const x = 'Sparklehorse';

// Task(reverse).ap(Task('Sparklehorse')) === Task(f => f('Sparklehorse')).ap(Task(reverse))
v.ap(Task.of(x)) === Task.of(f => f(x)).ap(v);
// Task('esrohelkrapS') === Task('esrohelkrapS')
```

### 组合律 (Composition)

最后是组合律（composition），这只是一种检查我们标准的函数组合在容器内应用时是否成立的方法。

```js
// composition
A.of(compose).ap(u).ap(v).ap(w) === u.ap(v.ap(w));
```

```js
const u = IO.of(toUpperCase);
const v = IO.of(concat('& beyond'));
const w = IO.of('blood bath ');

// 检查两种组合应用方式是否等价
IO.of(compose).ap(u).ap(v).ap(w) === u.ap(v.ap(w));
// IO('BLOOD BATH & BEYOND') === IO('BLOOD BATH & BEYOND')
```

## 总结

Applicative 的一个很好的用例是当一个人有多个函子参数时。它们使我们能够在函子世界内将函数应用于参数。虽然我们已经可以用 Monad 做到这一点，但当不需要 Monad 特定的功能时，我们应该更倾向于使用 Applicative 函子。

我们差不多完成了容器 API 的学习。我们已经学会了如何 `map`、`chain`，现在是 `ap` 函数。在下一章中，我们将学习如何更好地处理多个函子，并以有原则的方式分解它们。

[第十一章：再次转换，自然而然](ch11.md)


## 练习

{% exercise %}
使用 `add` 和 `map` 编写一个函数，将两个可能为 null 的数字相加。

{% initial src="./exercises/ch10/exercise_a.js#L3;" %}
```js
// safeAdd :: Maybe Number -> Maybe Number -> Maybe Number
const safeAdd = undefined; // 在这里填写你的代码
```


{% solution src="./exercises/ch10/solution_a.js" %}
{% validation src="./exercises/ch10/validation_a.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}


---


{% exercise %}
重写练习 b 中的 `safeAdd`，使用 `liftA2` 而不是 `ap`。

{% initial src="./exercises/ch10/exercise_b.js#L3;" %}
```js
// safeAdd :: Maybe Number -> Maybe Number -> Maybe Number
const safeAdd = undefined; // 在这里填写你的代码
```


{% solution src="./exercises/ch10/solution_b.js" %}
{% validation src="./exercises/ch10/validation_b.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}


---

对于下一个练习，我们考虑以下辅助函数：

```js
const localStorage = { // 模拟的 localStorage
  player1: { id:1, name: 'Albert' },
  player2: { id:2, name: 'Theresa' },
};

// getFromCache :: String -> IO User
// 从缓存中获取用户的 IO 操作
const getFromCache = x => new IO(() => localStorage[x]);

// game :: User -> User -> String
// 组合玩家姓名开始游戏的函数
const game = curry((p1, p2) => `${p1.name} vs ${p2.name}`);
```

{% exercise %}
编写一个 IO，从缓存中获取 player1 和 player2，然后开始游戏。


{% initial src="./exercises/ch10/exercise_c.js#L16;" %}
```js
// startGame :: IO String
const startGame = undefined; // 在这里填写你的代码
```


{% solution src="./exercises/ch10/solution_c.js" %}
{% validation src="./exercises/ch10/validation_c.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}