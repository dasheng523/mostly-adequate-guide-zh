# 第十二章：穿越顽石

到目前为止，在我们的“容器马戏团”（cirque du conteneur）里，你已经看到我们驯服了凶猛的[函子](ch08.md#my-first-functor)（functor），让它屈服于我们的意志，执行任何我们心血来潮的操作。你曾对使用函数[应用](ch10.md)（application）同时处理（杂耍般地）多种危险效果（effects）并收集结果的表演眼花缭乱。曾惊讶于容器通过[压平（joining）](ch09.md#joining)在一起而凭空消失。在副作用（side effect）的余兴表演中，我们看到它们被[组合（composed）](ch08.md#a-spot-of-theory)成一个。而最近，我们更是超越了自然，在你眼前将一种类型[转换（transformed）](ch11.md)成了另一种。

现在，我们的下一个戏法，将聚焦于遍历（traversals）。我们将看到类型（type）像空中飞人一样互相飞跃，同时保持我们的值（value）完好无损。我们将像旋转飞车里的吊舱一样重排效果。当我们的容器（container）像柔术演员的四肢一样缠绕在一起时，我们可以使用这个接口（interface）来理顺它们。我们将见证不同顺序带来的不同效果。拿上我的灯笼裤和滑哨，我们开始吧。

## 类型套类型

让我们来点不一样的：

```js
// readFile :: FileName -> Task Error String

// firstWords :: String -> String
const firstWords = compose(intercalate(' '), take(3), split(' '));

// tldr :: FileName -> Task Error String
const tldr = compose(map(firstWords), readFile);

map(tldr, ['file1', 'file2']);
// [Task('拥护君主制'), Task('粉碎父权制')]
```

这里我们读取了一堆文件，最终得到了一个没什么用的任务（Task）数组。我们该如何 `fork` 其中的每一个呢？如果我们能把类型交换一下，得到 `Task Error [String]` 而不是 `[Task Error String]`，那就太好了。这样，我们就能得到一个持有所有结果的未来值（future value），这比让几个未来值各自悠闲地到达，要更适合我们的异步需求。

这是最后一个棘手情况的例子：

```js
// getAttribute :: String -> Node -> Maybe String
// $ :: Selector -> IO Node

// getControlNode :: Selector -> IO (Maybe (IO Node))
const getControlNode = compose(map(map($)), map(getAttribute('aria-controls')), $);
```

看看那些渴望聚合在一起的 `IO`。要是能 `join`（压平）它们，让它们紧密贴合，那该多好，可惜啊，一个 `Maybe` 像舞会上的监护人一样挡在它们中间。这里最好的做法是把它们的位置挪到一起，这样每种类型最终都能聚合在一起，我们的签名就可以简化为 `IO (Maybe Node)`。

## 类型风水

*Traversable*（可遍历）接口包含两个强大的函数：`sequence` 和 `traverse`。

让我们用 `sequence` 来重新排列类型：

```js
sequence(List.of, Maybe.of(['the facts'])); // [Just('the facts')]
sequence(Task.of, new Map({ a: Task.of(1), b: Task.of(2) })); // Task(Map({ a: 1, b: 2 }))
sequence(IO.of, Either.of(IO.of('buckle my shoe'))); // IO(Right('buckle my shoe'))
sequence(Either.of, [Either.of('wing')]); // Right(['wing'])
sequence(Task.of, left('wing')); // Task(Left('wing'))
```

看到这里发生了什么吗？我们嵌套的类型就像在潮湿夏夜里的一条皮裤被翻了个底朝天。内层的函子被移到了外层，反之亦然。需要知道的是，`sequence` 对其参数有点挑剔。它看起来像这样：

```js
// sequence :: (Traversable t, Applicative f) => (a -> f a) -> t (f a) -> f (t a)
const sequence = curry((of, x) => x.sequence(of));
```

让我们从第二个参数开始。它必须是一个持有*应用函子*（Applicative）的*可遍历*（Traversable）类型，这听起来限制性很强，但实际上这种情况经常出现。正是 `t (f a)` 被转换成了 `f (t a)`。这难道不形象吗？两种类型就像跳方块舞（do-si-do）一样互相交换位置，一目了然。那里的第一个参数仅仅是一个辅助手段，只在无类型语言中才需要。它是一个类型构造器（type constructor）（即我们的 *of*），提供它的目的是为了让我们能够反转像 `Left` 这样不情愿被 map 的类型——稍后会详细介绍。

使用 `sequence`，我们可以像街头玩猜球戏法的人那样精确地移动类型。但它是如何工作的呢？让我们看看像 `Either` 这样的类型是如何实现它的：

```js
class Right extends Either {
  // ...
  sequence(of) {
    // 如果 this.$value 是一个应用函子，我们可以 map Either.of 到它上面
    return this.$value.map(Either.of);
  }
}
```

啊哈，如果我们的 `$value` 是一个函子（实际上，它必须是一个应用函子），我们可以简单地 `map` 我们的构造函数来“跳房子”般地越过这个类型。

你可能已经注意到我们完全忽略了 `of`。它是在映射无效的情况下传入的，就像 `Left` 的情况一样：

```js
class Left extends Either {
  // ...
  sequence(of) {
    // Left 不持有应用函子，所以我们直接使用提供的 of 函数
    return of(this);
  }
}
```

我们希望类型最终总能处于相同的排列方式，因此，像 `Left` 这样实际上并不持有我们内部应用函子的类型，就需要一点帮助来做到这一点。*Applicative* 接口要求我们首先有一个 *Pointed 函子*（Pointed Functor），所以我们总会有一个 `of` 可以传入。在有类型系统的语言中，外部类型可以从签名中推断出来，不需要显式给出。

## 效果分类

对于我们的容器而言，不同的顺序会产生不同的结果。如果我有一个 `[Maybe a]`，那它是一组可能存在的值；而如果我有一个 `Maybe [a]`，那它是一个可能存在的集合值。前者表示我们会比较宽容，保留“好的那些”，而后者则意味着这是一个“要么全有，要么全无”的情况。同样地，`Either Error (Task Error a)` 可以代表客户端验证，而 `Task Error (Either Error a)` 可以代表服务器端验证。类型可以互换以产生不同的效果。

```js
// fromPredicate :: (a -> Bool) -> a -> Either e a

// partition :: (a -> Bool) -> [a] -> [Either e a]
const partition = f => map(fromPredicate(f));

// validate :: (a -> Bool) -> [a] -> Either e [a]
const validate = f => traverse(Either.of, fromPredicate(f));
```

这里我们基于使用 `map` 还是 `traverse` 得到了两个不同的函数。第一个函数 `partition` 会根据谓词（predicate）函数给我们一个由 `Left` 和 `Right` 组成的数组。这对于保留有价值的数据以备将来使用很有用，而不是把它和洗澡水一起倒掉。而 `validate` 则会在第一个不满足谓词的项出现时给我们一个 `Left`，或者在所有项都符合要求（hunky dory）时给我们一个包含所有项的 `Right`。通过选择不同的类型顺序，我们得到了不同的行为。

让我们看看 `List` 的 `traverse` 函数，了解 `validate` 方法是如何实现的。

```js
traverse(of, fn) {
    return this.$value.reduce(
      (f, a) => fn(a).map(b => bs => bs.concat(b)).ap(f),
      of(new List([])),
    );
  }
```

这只是在列表上运行了一个 `reduce`。这个 reduce 函数是 `(f, a) => fn(a).map(b => bs => bs.concat(b)).ap(f)`，看起来有点吓人，让我们逐步分析一下。

1.  `reduce(..., ...)`

    记住 `reduce` 的签名：`reduce :: [a] -> (f -> a -> f) -> f -> f`。第一个参数实际上是由 `$value` 上的点表示法提供的，所以它是一个列表。
    然后我们需要一个函数，它接受一个 `f`（累加器 (accumulator)）和一个 `a`（被迭代项 (iteree)），并返回一个新的累加器。

2.  `of(new List([]))`

    种子值（seed value）是 `of(new List([]))`，在我们的例子中是 `Right([]) :: Either e [a]`。注意 `Either e [a]` 也将是我们的最终结果类型！

3.  `fn :: Applicative f => a -> f a`

    如果将其应用于我们上面的例子，`fn` 实际上是 `fromPredicate(f) :: a -> Either e a`。
    > fn(a) :: Either e a

4.  `.map(b => bs => bs.concat(b))`

    当值为 `Right` 时，`Either.map` 将 right 值传递给函数，并返回一个包含结果的新 `Right`。在这种情况下，该函数有一个参数（`b`），并返回另一个函数（`bs => bs.concat(b)`，其中 `b` 由于闭包（closure）而在作用域内）。当值为 `Left` 时，返回 left 值。
    > fn(a).map(b => bs => bs.concat(b)) :: Either e ([a] -> [a])

5.  .`ap(f)`

    记住这里的 `f` 是一个应用函子，所以我们可以将函数 `bs => bs.concat(b)` 应用于 `f` 中的任何值 `bs :: [a]`。幸运的是，`f` 来自我们的初始种子值，并且具有以下类型：`f :: Either e [a]`，顺便说一句，当我们应用 `bs => bs.concat(b)` 时，这个类型得以保留。
    当 `f` 是 `Right` 时，它会调用 `bs => bs.concat(b)`，返回一个将项添加到列表后的 `Right`。当值为 `Left` 时，返回 left 值（分别来自上一步或上一次迭代）。
    > fn(a).map(b => bs => bs.concat(b)).ap(f) :: Either e [a]

这个看似神奇的转换仅通过 `List.traverse` 中区区 6 行代码就实现了，并且是利用 `of`、`map` 和 `ap` 完成的，因此它适用于任何应用函子（Applicative Functor）。这是一个很好的例子，说明了这些抽象如何帮助我们编写高度通用的代码，而只需做出很少的假设（顺便说一句，这些假设可以在类型级别声明和检查！）。

## 类型的华尔兹

是时候回顾并清理我们最初的例子了。

```js
// readFile :: FileName -> Task Error String

// firstWords :: String -> String
const firstWords = compose(intercalate(' '), take(3), split(' '));

// tldr :: FileName -> Task Error String
const tldr = compose(map(firstWords), readFile);

traverse(Task.of, tldr, ['file1', 'file2']);
// Task(['拥护君主制', '粉碎父权制']);
```

使用 `traverse` 而不是 `map`，我们成功地将那些不守规矩的 `Task` 归集成一个协调一致的结果数组。如果你熟悉的话，这就像 `Promise.all()`，但它不仅仅是一个一次性的自定义函数，不，它适用于任何*可遍历*（traversable）类型。这些数学化的 API 倾向于以可互操作、可重用的方式捕获我们想做的大多数事情，而不是让每个库都为单一类型重新发明这些函数。

让我们清理最后一个例子来收尾（不，不是闭包那种收尾）：

```js
// getAttribute :: String -> Node -> Maybe String
// $ :: Selector -> IO Node

// getControlNode :: Selector -> IO (Maybe Node)
const getControlNode = compose(chain(traverse(IO.of, $)), map(getAttribute('aria-controls')), $);
```

我们用 `chain(traverse(IO.of, $))` 替代了 `map(map($))`，它在映射时反转了我们的类型，然后通过 `chain` 压平了两个 `IO`。

## 没有法律与秩序

好了，在你变得吹毛求疵、像敲法槌一样猛敲退格键想要退出本章之前，花点时间认识到这些定律（laws）是很有用的代码保证。我的猜想是，大多数程序架构的目标都是试图对我们的代码施加有用的限制，以缩小可能性，从而在设计者和阅读者层面引导我们找到答案。

没有定律的接口仅仅是一层间接调用。像任何其他数学结构一样，为了我们自己（心智健全）着想，我们必须公开其属性。这具有与封装（encapsulation）类似的效果，因为它保护了数据，使我们能够将接口替换为另一个遵纪守法（law abiding）的实现。

跟上，我们有一些定律需要弄清楚。

### 恒等定律 (Identity)

```js
const identity1 = compose(sequence(Identity.of), map(Identity.of));
const identity2 = Identity.of;

// 用 Right 来测试一下
identity1(Either.of('stuff'));
// Identity(Right('stuff'))

identity2(Either.of('stuff'));
// Identity(Right('stuff'))
```

这应该很直观。如果我们将一个 `Identity` 放入我们的函子中，然后用 `sequence` 将其内外翻转，这与一开始就将其放在外部是相同的。我们选择 `Right` 作为试验品，因为它易于尝试和检验该定律。在那里使用任意函子是正常的，然而，在此处定律本身中使用具体的函子，即 `Identity`，可能会让人感到意外。回想一下，范畴（category）是由其对象（objects）之间的态射（morphisms）定义的，这些态射具有可结合的组合（composition）和恒等（identity）特性。当处理函子范畴时，自然变换（natural transformations）是态射，而 `Identity` 就是那个恒等。`Identity` 函子在演示定律方面与我们的 `compose` 函数一样基础。事实上，我们应该放弃挣扎，对我们的 [Compose](ch08.md#a-spot-of-theory) 类型也遵循同样的模式：

### 组合定律 (Composition)

```js
const comp1 = compose(sequence(Compose.of), map(Compose.of));
const comp2 = (Fof, Gof) => compose(Compose.of, map(sequence(Gof)), sequence(Fof));


// 用我们手头现有的一些类型来测试一下
comp1(Identity(Right([true])));
// Compose(Right([Identity(true)]))

comp2(Either.of, Array)(Identity(Right([true])));
// Compose(Right([Identity(true)]))
```

正如所期望的，这条定律保持了组合性：如果我们交换函子的组合，我们不应该看到任何意外，因为组合本身也是一个函子。我们随意选择了 `true`、`Right`、`Identity` 和 `Array` 来进行测试。像 [quickcheck](https://hackage.haskell.org/package/QuickCheck) 或 [jsverify](http://jsverify.github.io/) 这样的库可以通过对输入进行模糊测试（fuzz testing）来帮助我们测试定律。

作为上述定律的一个自然结果，我们获得了[融合遍历](https://www.cs.ox.ac.uk/jeremy.gibbons/publications/iterator.pdf)（fuse traversals）的能力，从性能角度来看这很好。

### 自然性定律 (Naturality)

```js
const natLaw1 = (of, nt) => compose(nt, sequence(of));
const natLaw2 = (of, nt) => compose(sequence(of), map(nt));

// 用一个随机的自然变换和我们友好的 Identity/Right 函子来测试。

// maybeToEither :: Maybe a -> Either () a
const maybeToEither = x => (x.$value ? new Right(x.$value) : new Left());

natLaw1(Maybe.of, maybeToEither)(Identity.of(Maybe.of('barlow one')));
// Right(Identity('barlow one'))

natLaw2(Either.of, maybeToEither)(Identity.of(Maybe.of('barlow one')));
// Right(Identity('barlow one'))
```

这与我们的恒等定律类似。如果我们先交换类型，然后在外部运行一个自然变换，这应该等同于先映射一个自然变换，然后再翻转类型。

这个定律的一个自然推论是：

```js
traverse(A.of, A.of) === A.of;
```

同样，从性能的角度来看，这很好。

## 总结

*Traversable* 是一个强大的接口，它让我们能够像用意念操控的室内设计师一样轻松地重新排列类型。我们可以通过不同的顺序实现不同的效果，并抚平那些阻碍我们 `join`（压平）它们的讨厌的类型皱褶。接下来，我们将稍微绕道，去看看函数式编程乃至整个代数中最强大的接口之一：[幺半群将一切聚合](ch13-zh.md)

## 练习

考虑以下元素：

```js
// httpGet :: Route -> Task Error JSON

// routes :: Map Route Route
const routes = new Map({ '/': '/', '/about': '/about' });
```

{% exercise %}
使用 traversable 接口将 `getJsons` 的类型签名更改为
Map Route Route → Task Error (Map Route JSON)


{% initial src="./exercises/ch12/exercise_a.js#L11;" %}
```js
// getJsons :: Map Route Route -> Map Route (Task Error JSON)
const getJsons = map(httpGet);
```


{% solution src="./exercises/ch12/solution_a.js" %}
{% validation src="./exercises/ch12/validation_a.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}


---


我们现在定义以下验证函数：

```js
// validate :: Player -> Either String Player
const validate = player => (player.name ? Either.of(player) : left('必须有名字'));
```

{% exercise %}
使用 traversable 和 `validate` 函数，更新 `startGame`（及其签名），使得只有当所有玩家都有效时才开始游戏


{% initial src="./exercises/ch12/exercise_b.js#L7;" %}
```js
// startGame :: [Player] -> [Either Error String]
const startGame = compose(map(map(always('游戏开始！'))), map(validate));
```


{% solution src="./exercises/ch12/solution_b.js" %}
{% validation src="./exercises/ch12/validation_b.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}


---


最后，我们考虑一些文件系统辅助函数：

```js
// readfile :: String -> String -> Task Error String
// readdir :: String -> Task Error [String]
```

{% exercise %}
使用 traversable 来重新排列并压平嵌套的 Task 和 Maybe


{% initial src="./exercises/ch12/exercise_c.js#L8;" %}
```js
// readFirst :: String -> Task Error (Maybe (Task Error String))
const readFirst = compose(map(map(readfile('utf-8'))), map(safeHead), readdir);
```


{% solution src="./exercises/ch12/solution_c.js" %}
{% validation src="./exercises/ch12/validation_c.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}
