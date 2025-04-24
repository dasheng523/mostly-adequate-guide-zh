# 第 11 章：再次变换，自然而然

我们将要在日常代码的实用场景下讨论*自然变换*（natural transformations）。它们恰好是范畴论（category theory）的一大支柱，在运用数学来推理和重构代码时绝对不可或缺。因此，我认为有责任告知各位，由于本人认知所限，你们即将见证的无疑是一种令人扼腕的不公。那么，我们开始吧。

## 诅咒这嵌套

我想谈谈嵌套（nesting）的问题。不是准父母们感受到的那种整理和重新布置、带有强迫症倾向的筑巢本能冲动，而是……嗯，好吧，仔细想想，这和我们将在接下来几章看到的也相差不远……无论如何，我所说的*嵌套*是指将两个或多个不同的类型层层包裹在一个值周围，仿佛呵护新生儿一般。

```js
Right(Maybe('b'));

IO(Task(IO(1000)));

[Identity('bee thousand')];
```

到目前为止，我们通过精心设计的例子成功避开了这种常见场景，但在实践中，随着编码的进行，类型往往会像驱魔仪式中的耳机线一样缠作一团。如果我们不随时细致地整理类型，我们的代码读起来会比猫咖啡馆里的垮掉派诗人还要毛茸茸。

## 一出情景喜剧

```js
// getValue :: Selector -> Task Error (Maybe String)
// postComment :: String -> Task Error Comment
// validate :: String -> Either ValidationError String

// saveComment :: () -> Task Error (Maybe (Either ValidationError (Task Error Comment)))
const saveComment = compose(
  map(map(map(postComment))),
  map(map(validate)),
  getValue('#comment'),
);
```

所有角色都到齐了，这让我们的类型签名（type signature）大为懊恼。请允许我简要解释一下这段代码。我们首先通过 `getValue('#comment')` 获取用户输入，这是一个检索元素文本的操作。现在，它在查找元素时可能会出错，或者值字符串可能不存在，所以它返回 `Task Error (Maybe String)`。之后，我们必须同时对 `Task` 和 `Maybe` 进行 `map` 操作，将文本传递给 `validate`，而 `validate` 反过来会给我们一个 `Either ValidationError` 或我们的 `String`。然后是一连串的 `map` 操作，将我们当前 `Task Error (Maybe (Either ValidationError String))` 中的 `String` 发送给 `postComment`，后者返回我们最终的 `Task`。

真是一团糟。这是抽象类型的大杂烩、业余类型表现主义、多态（polymorphic）的波洛克、整体的蒙德里安。对于这个常见问题有很多解决方案。我们可以将类型组合（compose）成一个庞大的容器、排序并 `join`（合并）其中几个、将它们同质化（homogenize）、解构它们等等。在本章中，我们将专注于通过*自然变换*来同质化它们。

## 全都自然

*自然变换*是“函子（functors）之间的态射（morphism）”，也就是说，是作用于容器本身的函数。从类型上看，它是一个函数 `(Functor f, Functor g) => f a -> g a`。它的特别之处在于，我们无论如何都不能窥视函子内部的内容。可以把它想象成高度机密信息的交换——双方都不知道盖有“绝密”印章的马尼拉信封里装的是什么。这是一种结构性操作。一种函子式的服装更换。形式上，*自然变换*是任何满足以下条件的函数：

<img width=600 src="images/natural_transformation.png" alt="自然变换图示" />

或者用代码表示：

```js
// nt :: (Functor f, Functor g) => f a -> g a
// nt 是一个自然变换函数
compose(map(f), nt) === compose(nt, map(f));
```

图示和代码都表达了相同的意思：我们可以先运行自然变换然后 `map`，或者先 `map` 然后运行自然变换，得到的结果是相同的。顺便一提，这可以从一个[自由定理（free theorem）](ch07.md#free-as-in-theorem)推导出来，尽管自然变换（和函子）并不局限于作用于类型的函数。

## 有原则的类型转换

作为程序员，我们熟悉类型转换。我们将 `Strings` 转换为 `Booleans`，将 `Integers` 转换为 `Floats`（尽管 JavaScript 只有 `Numbers`）。这里的区别仅仅在于我们处理的是代数容器，并且我们有一些理论可供利用。

让我们看一些例子：

```js
// idToMaybe :: Identity a -> Maybe a
const idToMaybe = x => Maybe.of(x.$value);

// idToIO :: Identity a -> IO a
const idToIO = x => IO.of(x.$value);

// eitherToTask :: Either a b -> Task a b
const eitherToTask = either(Task.rejected, Task.of);

// ioToTask :: IO a -> Task () a
const ioToTask = x => new Task((reject, resolve) => resolve(x.unsafePerform()));

// maybeToTask :: Maybe a -> Task () a
const maybeToTask = x => (x.isNothing ? Task.rejected() : Task.of(x.$value));

// arrayToMaybe :: [a] -> Maybe a
const arrayToMaybe = x => Maybe.of(x[0]);
```

明白了吗？我们只是将一个函子变成另一个。在这个过程中允许丢失信息，只要我们将来要 `map` 的那个值不会在形态变换的混乱中丢失就行。这正是关键所在：根据我们的定义，即使在转换之后，`map` 也必须能够继续进行。

一种看待它的方式是，我们正在转换我们的效果（effects）。从这个角度看，我们可以将 `ioToTask` 视为将同步转换为异步，或者将 `arrayToMaybe` 从非确定性转换为可能的失败。请注意，在 JavaScript 中我们无法将异步转换为同步，所以我们不能编写 `taskToIO` ——那将是一种超自然（supernatural）转换。

## 特性嫉妒

假设我们想使用另一个类型（比如 `List`）的某些特性，例如 `sortBy`。*自然变换*提供了一种很好的方式来转换到目标类型，同时确保我们的 `map` 操作仍然可靠。

```js
// arrayToList :: [a] -> List a
const arrayToList = List.of;

const doListyThings = compose(sortBy(h), filter(g), arrayToList, map(f));
const doListyThings_ = compose(sortBy(h), filter(g), map(f), arrayToList); // 应用定律
```

鼻子一动，魔杖轻点三下，放入 `arrayToList`，瞧！我们的 `[a]` 就变成了一个 `List a`，如果愿意，我们就可以 `sortBy` 了。

此外，通过将 `map(f)` 移动到*自然变换*的左侧（如 `doListyThings_` 所示），可以更容易地优化/融合操作。

## 同构的 JavaScript

当我们可以在两种类型之间来回转换而完全不丢失任何信息时，这被认为是*同构*（isomorphism）。这只是“持有相同数据”的一个花哨说法。如果我们可以提供“到”（to）和“从”（from）的*自然变换*作为证明，我们就说这两种类型是*同构*的：

```js
// promiseToTask :: Promise a b -> Task a b
const promiseToTask = x => new Task((reject, resolve) => x.then(resolve).catch(reject));

// taskToPromise :: Task a b -> Promise a b
const taskToPromise = x => new Promise((resolve, reject) => x.fork(reject, resolve));

const x = Promise.resolve('ring');
taskToPromise(promiseToTask(x)) === x; // true

const y = Task.of('rabbit');
promiseToTask(taskToPromise(y)) === y; // true
```

Q.E.D. `Promise` 和 `Task` 是*同构*的。我们也可以编写一个 `listToArray` 来补充我们的 `arrayToList`，并证明它们也是同构的。作为一个反例，`arrayToMaybe` 不是一个*同构*，因为它会丢失信息：

```js
// maybeToArray :: Maybe a -> [a]
const maybeToArray = x => (x.isNothing ? [] : [x.$value]);

// arrayToMaybe :: [a] -> Maybe a
const arrayToMaybe = x => Maybe.of(x[0]);

const x = ['elvis costello', 'the attractions'];

// 非同构
maybeToArray(arrayToMaybe(x)); // ['elvis costello']

// 但是一个自然变换
compose(arrayToMaybe, map(replace('elvis', 'lou')))(x); // Just('lou costello')
// ==
compose(map(replace('elvis', 'lou')), arrayToMaybe)(x); // Just('lou costello')
```

然而，它们确实是*自然变换*，因为在任意一边进行 `map` 操作都会得到相同的结果。我在本章讲到这里时顺便提到了*同构*，但别被这迷惑了，它们是一个极其强大且普遍的概念。不管怎样，我们继续。

## 更广泛的定义

这些结构性函数绝不局限于类型转换。

这里有几个不同的例子：

```hs
reverse :: [a] -> [a]

join :: (Monad m) => m (m a) -> m a

head :: [a] -> a

of :: a -> f a
```

自然变换定律对这些函数同样适用。可能让你困惑的一点是 `head :: [a] -> a` 可以被视为 `head :: [a] -> Identity a`。在证明定律时，我们可以随心所欲地插入 `Identity`，因为我们反过来可以证明 `a` 与 `Identity a` 是同构的（看吧，我告诉过你*同构*无处不在）。

## 一种嵌套解决方案

回到我们那喜剧般的类型签名。我们可以在调用代码中散布一些*自然变换*来强制转换每个不同的类型，使它们统一，从而可以 `join`。

```js
// getValue :: Selector -> Task Error (Maybe String)
// postComment :: String -> Task Error Comment
// validate :: String -> Either ValidationError String

// saveComment :: () -> Task Error Comment
const saveComment = compose(
  chain(postComment),
  chain(eitherToTask), // Either -> Task 然后 join
  map(validate),
  chain(maybeToTask),  // Maybe -> Task 然后 join
  getValue('#comment'),
);
```

那么这里我们做了什么？我们仅仅添加了 `chain(maybeToTask)` 和 `chain(eitherToTask)`。两者效果相同；它们都自然地将我们 `Task` 持有的函子转换为另一个 `Task`，然后 `join` 这两个 `Task`。就像窗台上的防鸟刺一样，我们从源头上避免了嵌套。正如光明之城的人们所说，“Mieux vaut prévenir que guérir”（预防胜于治疗）——一分预防胜过十分治疗。

## 总结

*自然变换*是作用于我们函子本身的函数。它们是范畴论中极其重要的概念，并且随着更多抽象概念的引入将开始无处不在，但目前，我们已将它们的应用范围限定在几个具体的场景中。正如我们所见，我们可以通过转换类型来达到不同的效果，并保证我们的组合（composition）是可靠的。它们也可以帮助我们处理嵌套类型，尽管它们的普遍效果是将我们的函子同质化到最低的共同标准，这在实践中通常是具有最易变效果的函子（在大多数情况下是 `Task`）。

这种持续而乏味的类型整理是我们为具象化这些类型——从以太中召唤它们——所付出的代价。当然，隐式的副作用要阴险得多，所以我们在这里进行着正义的斗争。在能够驾驭更大型的类型融合之前，我们还需要工具箱里有更多的工具。接下来，我们将学习使用 *Traversable* 来重新排序我们的类型。

[第 12 章：遍历顽石](ch12-zh.md)


## 练习

{% exercise %}
编写一个自然变换，将 `Either b a` 转换为 `Maybe a`

{% initial src="./exercises/ch11/exercise_a.js#L3;" %}
```js
// eitherToMaybe :: Either b a -> Maybe a
const eitherToMaybe = undefined;
```


{% solution src="./exercises/ch11/solution_a.js" %}
{% validation src="./exercises/ch11/validation_a.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}


---


```js
// eitherToTask :: Either a b -> Task a b
const eitherToTask = either(Task.rejected, Task.of);
```

{% exercise %}
使用 `eitherToTask` 简化 `findNameById`，移除嵌套的 `Either`。

{% initial src="./exercises/ch11/exercise_b.js#L6;" %}
```js
// findNameById :: Number -> Task Error (Either Error User)
const findNameById = compose(map(map(prop('name'))), findUserById);
```


{% solution src="./exercises/ch11/solution_b.js" %}
{% validation src="./exercises/ch11/validation_b.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}


---


提醒一下，以下函数在练习的上下文中可用：

```hs
split :: String -> String -> [String]
intercalate :: String -> [String] -> String
```

{% exercise %}
编写 String 和 [Char] 之间的同构。

{% initial src="./exercises/ch11/exercise_c.js#L8;" %}
```js
// strToList :: String -> [Char]
const strToList = undefined;

// listToStr :: [Char] -> String
const listToStr = undefined;
```


{% solution src="./exercises/ch11/solution_c.js" %}
{% validation src="./exercises/ch11/validation_c.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}