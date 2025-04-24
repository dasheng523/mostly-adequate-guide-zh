# 第九章：Monad 洋葱

## Pointed 函子工厂

在我们继续之前，我必须坦白一件事：对于我们放在每种类型上的那个 `of` 方法，我并没有完全坦诚。事实证明，它不是为了避免 `new` 关键字而存在的，而是为了将值放入所谓的*默认最小上下文*（default minimal context）中。是的，`of` 实际上并不能取代构造函数——它是我们称为 *Pointed* 的重要接口的一部分。

> *Pointed 函子*（pointed functor）是带有 `of` 方法的函子（functor）。

这里重要的是能够将任何值放入我们的类型中并开始进行映射（mapping）。

```js
IO.of('tetris').map(concat(' master'));
// IO('tetris master') // 将 'tetris' 放入 IO，然后映射

Maybe.of(1336).map(add(1));
// Maybe(1337) // 将 1336 放入 Maybe，然后映射

Task.of([{ id: 2 }, { id: 3 }]).map(map(prop('id')));
// Task([2,3]) // 将数组放入 Task，然后映射内部数组

Either.of('The past, present and future walk into a bar...').map(concat('it was tense.'));
// Right('The past, present and future walk into a bar...it was tense.') // 将字符串放入 Either (Right)，然后映射
```

如果你还记得，`IO` 和 `Task` 的构造函数期望一个函数作为它们的参数，但 `Maybe` 和 `Either` 不是。这个接口的动机是一种通用的、一致的方式将值放入我们的函子中，而无需构造函数的复杂性和特定要求。“默认最小上下文”这个术语缺乏精确性，但很好地抓住了思想：我们希望将任何值提升（lift）到我们的类型中，并像往常一样使用任何函子的预期行为进行 `map`。

在这一点上，我必须做一个重要的修正（双关语）：`Left.of` 没有任何意义。每个函子必须有一种将值放入其中的方法，对于 `Either` 来说，那就是 `new Right(x)`。我们使用 `Right` 来定义 `of`，因为如果我们的类型*可以* `map`，它就*应该* `map`。看看上面的例子，我们应该对 `of` 通常如何工作有一个直觉，而 `Left` 打破了那个模式。

你可能听说过诸如 `pure`、`point`、`unit` 和 `return` 之类的函数。这些都是我们 `of` 方法的各种别名，一个神秘的国际函数。当我们开始使用 Monad 时，`of` 会变得很重要，因为正如我们将看到的，我们有责任手动将值放回类型中。

为了避免 `new` 关键字，有几种标准的 JavaScript 技巧或库，所以让我们使用它们，并从现在开始像一个负责任的成年人一样使用 `of`。我建议使用来自 `folktale`、`ramda` 或 `fantasy-land` 的函子实例，因为它们提供了正确的 `of` 方法以及不依赖 `new` 的好用的构造函数。


## 混合隐喻

<img src="images/onion.png" alt="洋葱" />

你看，除了太空卷饼（space burritos，如果你听过传闻的话），Monad 还像洋葱。请允许我用一个常见的情况来演示：

```js
const fs = require('fs');

// readFile :: String -> IO String
const readFile = filename => new IO(() => fs.readFileSync(filename, 'utf-8')); // 读取文件内容到 IO

// print :: String -> IO String
const print = x => new IO(() => { // 打印内容并返回内容的 IO
  console.log(x);
  return x;
});

// cat :: String -> IO (IO String)
// 先 readFile，然后 map(print)
// 由于 print 返回 IO，结果是 IO(IO String)
const cat = compose(map(print), readFile);

cat('.git/config');
// IO(IO('[core]\nrepositoryformatversion = 0\n')) // 概念上的嵌套 IO
```

我们这里得到的是一个 `IO` 被困在另一个 `IO` 里面，因为 `print` 在我们的 `map` 过程中引入了第二个 `IO`。为了继续处理我们的字符串，我们必须 `map(map(f))`，并且为了观察效果，我们必须 `unsafePerformIO().unsafePerformIO()`。

```js
// cat :: String -> IO (IO String)
const cat = compose(map(print), readFile);

// catFirstChar :: String -> IO (IO String)
// 在嵌套的 IO 上再 map 一次来获取第一个字符
const catFirstChar = compose(map(map(head)), cat);

catFirstChar('.git/config');
// IO(IO('[')) // 概念上的结果
```

虽然很高兴看到我们有两个效果被打包好并准备在我们的应用程序中使用，但这感觉有点像穿着两层防护服工作，我们最终得到了一个令人不安的笨拙 API。让我们看看另一种情况：

```js
// safeProp :: Key -> {Key: a} -> Maybe a
const safeProp = curry((x, obj) => Maybe.of(obj[x])); // 安全地获取对象属性

// safeHead :: [a] -> Maybe a
const safeHead = safeProp(0); // 安全地获取数组头部

// firstAddressStreet :: User -> Maybe (Maybe (Maybe Street))
// 组合 safeProp 和 safeHead，每次都返回 Maybe，导致嵌套
const firstAddressStreet = compose(
  map(map(safeProp('street'))), // 第三层 Maybe
  map(safeHead),               // 第二层 Maybe
  safeProp('addresses'),         // 第一层 Maybe
);

firstAddressStreet({
  addresses: [{ street: { name: 'Mulburry', number: 8402 }, postcode: 'WC2N' }],
});
// Maybe(Maybe(Maybe({name: 'Mulburry', number: 8402}))) // 三层嵌套的 Maybe
```

我们再次看到这种嵌套函子的情况，虽然看到函数中有三个可能的失败点很整洁，但期望调用者 `map` 三次来获取值有点冒昧——我们才刚认识。这种模式会一次又一次地出现，这是我们需要将强大的 Monad 符号投射到夜空中的主要情况。

我说 Monad 像洋葱，因为当我们用 `map` 剥开嵌套函子的每一层以获取内部值时，眼泪会涌出。我们可以擦干眼泪，深吸一口气，并使用一个叫做 `join` 的方法。

```js
const mmo = Maybe.of(Maybe.of('nunchucks'));
// Maybe(Maybe('nunchucks'))

mmo.join(); // 移除一层 Maybe
// Maybe('nunchucks')

const ioio = IO.of(IO.of('pizza'));
// IO(IO('pizza'))

ioio.join(); // 移除一层 IO
// IO('pizza')

const ttt = Task.of(Task.of(Task.of('sewers')));
// Task(Task(Task('sewers')));

ttt.join(); // 移除一层 Task
// Task(Task('sewers'))
```

如果我们有两层相同类型的嵌套，我们可以用 `join` 将它们压扁（smash them together）。这种结合在一起的能力，这种函子的结合（functor matrimony），正是使 Monad 成为 Monad 的原因。让我们用一个更准确一点的定义来逐步接近完整的定义：

> Monad 是可以被压平（flatten）的 Pointed 函子。

任何定义了 `join` 方法、拥有 `of` 方法并遵守一些定律的函子都是 Monad。定义 `join` 并不太难，所以让我们为 `Maybe` 定义一个：

```js
Maybe.prototype.join = function join() {
  // 如果是 Nothing，返回 Maybe.of(null) (即 Nothing)
  // 否则，返回内部的值 (它本身就是一个 Maybe)
  return this.isNothing ? Maybe.of(null) : this.$value;
};
```

好了，简单得就像在子宫里吞噬自己的双胞胎一样。如果我们有一个 `Maybe(Maybe(x))`，那么 `.$value` 将只移除不必要的额外层，我们可以安全地从那里进行 `map`。否则，我们将只有一个 `Maybe`，因为一开始就不会有任何东西被映射。

现在我们有了一个 `join` 方法，让我们在 `firstAddressStreet` 例子上撒一些神奇的 Monad 尘埃，看看它的作用：

```js
// join :: Monad m => m (m a) -> m a
const join = mma => mma.join(); // 辅助函数调用 join 方法

// firstAddressStreet :: User -> Maybe Street
const firstAddressStreet = compose(
  join, // 第三步后 join
  map(safeProp('street')), // 第三步：Maybe(Maybe(Maybe Street)) -> Maybe(Maybe(Maybe Street)) 映射内部 Maybe
  join, // 第二步后 join
  map(safeHead), // 第二步：Maybe(Maybe [Address]) -> Maybe(Maybe(Maybe Address)) 映射内部 Maybe
  safeProp('addresses'), // 第一步：User -> Maybe [Address]
);

firstAddressStreet({
  addresses: [{ street: { name: 'Mulburry', number: 8402 }, postcode: 'WC2N' }],
});
// Maybe({name: 'Mulburry', number: 8402}) // 最终结果，只有一层 Maybe
```

我们在遇到嵌套 `Maybe` 的地方添加了 `join`，以防止它们失控。让我们对 `IO` 做同样的事情，以便感受一下。

```js
IO.prototype.join = function() {
  const io = this; // 引用外部 IO
  // 返回一个新的 IO，它会先执行外部 IO 的操作，再执行内部 IO 的操作
  return new IO(() => io.unsafePerformIO().unsafePerformIO());
};
```

我们只是按顺序捆绑运行两层 IO：先是外部的，然后是内部的。请注意，我们没有抛弃纯粹性，只是将过多的两层收缩包装重新打包成一个更易于打开的包。

```js
// log :: a -> IO a
const log = x => new IO(() => { // 日志记录函数，返回 IO
  console.log(x);
  return x;
});

// setStyle :: Selector -> CSSProps -> IO DOM
const setStyle = // 设置样式的函数，返回 IO
  curry((sel, props) => new IO(() => $(sel).css(props))); // jQuery 选择器简写

// getItem :: String -> IO String
const getItem = key => new IO(() => localStorage.getItem(key)); // 从 localStorage 获取值的函数，返回 IO

// applyPreferences :: String -> IO DOM
const applyPreferences = compose(
  join, // 第四步后 join
  map(setStyle('#main')), // 第四步：IO String -> IO(IO DOM)
  join, // 第二步后 join
  map(log), // 第二步：IO String -> IO(IO String)
  map(JSON.parse), // 第一步：IO String -> IO String
  getItem, // 起始：String -> IO String
);

applyPreferences('preferences').unsafePerformIO(); // 执行整个 IO 操作链
// Object {backgroundColor: "green"} // log 输出
// <div style="background-color: 'green'"/> // setStyle 的效果 (概念上的 DOM)
```

`getItem` 返回一个 `IO String`，所以我们 `map` 来解析它。`log` 和 `setStyle` 本身都返回 `IO`，所以我们必须 `join` 来控制我们的嵌套。

## 我的链条击打我的胸膛

<img src="images/chain.jpg" alt="链条" />

你可能已经注意到一个模式。我们经常在 `map` 之后紧接着调用 `join`。让我们将此抽象为一个名为 `chain` 的函数。

```js
// chain :: Monad m => (a -> m b) -> m a -> m b
const chain = curry((f, m) => m.map(f).join()); // 先 map 再 join

// 或者

// chain :: Monad m => (a -> m b) -> m a -> m b
const chain = f => compose(join, map(f)); // 组合 join 和 map(f)
```

我们只是将这个 map/join 组合捆绑到一个函数中。如果你以前读过关于 Monad 的文章，你可能见过 `chain` 被称为 `>>=`（读作 bind）或 `flatMap`，它们都是同一概念的别名。我个人认为 `flatMap` 是最准确的名称，但我们将坚持使用 `chain`，因为它是 JS 中广泛接受的名称。让我们用 `chain` 重构上面的两个例子：

```js
// 使用 map/join
const firstAddressStreet = compose(
  join,
  map(safeProp('street')),
  join,
  map(safeHead),
  safeProp('addresses'),
);

// 使用 chain
const firstAddressStreet = compose(
  chain(safeProp('street')), // 替换 map/join
  chain(safeHead),           // 替换 map/join
  safeProp('addresses'),
);

// 使用 map/join
const applyPreferences = compose(
  join,
  map(setStyle('#main')),
  join,
  map(log),
  map(JSON.parse),
  getItem,
);

// 使用 chain
const applyPreferences = compose(
  chain(setStyle('#main')), // 替换 map/join
  chain(log),             // 替换 map/join
  map(JSON.parse), // 这里仍然是 map，因为 JSON.parse 不返回 IO
  getItem,
);
```

我用我们新的 `chain` 函数替换了任何 `map/join` 组合，以稍微整理一下。整洁固然好，但 `chain` 的意义远不止表面所见——它更像龙卷风而不是吸尘器。因为 `chain` 毫不费力地嵌套效果，我们可以以纯函数的方式捕获*序列*（sequence）和*变量赋值*（variable assignment）。

```js
// getJSON :: Url -> Params -> Task JSON
getJSON('/authenticate', { username: 'stale', password: 'crackers' })
  .chain(user => getJSON('/friends', { user_id: user.id })); // 链式异步调用：先认证，然后获取朋友列表
// Task([{name: 'Seimith', id: 14}, {name: 'Ric', id: 39}]); // 概念上的结果

// querySelector :: Selector -> IO DOM
querySelector('input.username')
  .chain(({ value: uname }) => // 获取用户名
    querySelector('input.email') // 获取 email
      .chain(({ value: email }) => IO.of(`Welcome ${uname} prepare for spam at ${email}`)) // 使用 uname 和 email
  );
// IO('Welcome Olivia prepare for spam at olivia@tremorcontrol.net'); // 概念上的结果

Maybe.of(3)
  .chain(three => Maybe.of(2).map(add(three))); // 链式 Maybe 计算：获取 3，然后加到 Maybe(2) 上
// Maybe(5);

Maybe.of(null) // 起始值为 Nothing
  .chain(safeProp('address')) // 由于是 Nothing，这里短路
  .chain(safeProp('street')); // 这里也短路
// Maybe(null); // 最终结果是 Nothing (实际上是 Maybe.of(null))
```

我们本可以用 `compose` 来写这些例子，但我们需要一些辅助函数，而且这种风格无论如何都有利于通过闭包进行显式变量赋值。相反，我们使用的是 `chain` 的中缀（infix）版本，顺便说一句，对于任何类型，它都可以自动从 `map` 和 `join` 推导出来：`t.prototype.chain = function(f) { return this.map(f).join(); }`。如果我们想要一种虚假的性能感，我们也可以手动定义 `chain`，尽管我们必须注意保持正确的功能——也就是说，它必须等于 `map` 后跟 `join`。一个有趣的事实是，如果我们创建了 `chain`，我们可以免费推导出 `map`，只需在完成时用 `of` 将值重新装瓶即可。有了 `chain`，我们也可以将 `join` 定义为 `chain(id)`。这可能感觉像是在和镶钻魔术师玩德州扑克，我只是随手变出东西来，但是，就像大多数数学一样，所有这些有原则的构造都是相互关联的。许多这些推导在 [fantasyland](https://github.com/fantasyland/fantasy-land) 仓库中都有提及，这是 JavaScript 中代数数据类型（algebraic data types）的官方规范。

无论如何，让我们看看上面的例子。在第一个例子中，我们看到两个 `Task` 被链接在一系列异步操作中——首先它检索 `user`，然后用该用户的 id 查找朋友。我们使用 `chain` 来避免 `Task(Task([Friend]))` 的情况。

接下来，我们使用 `querySelector` 来查找几个不同的输入并创建一个欢迎消息。注意我们如何在最内层函数中同时访问 `uname` 和 `email`——这是函数式变量赋值的最佳体现。由于 `IO` 慷慨地借给我们它的值，我们负责将其放回原样——我们不想破坏它的信任（和我们的程序）。`IO.of` 是完成这项工作的完美工具，这就是为什么 Pointed 是 Monad 接口的重要先决条件。然而，我们可以选择 `map`，因为那也会返回正确的类型：

```js
querySelector('input.username').chain(({ value: uname }) =>
  querySelector('input.email').map(({ value: email }) => // 注意这里是 map，因为返回的是普通字符串
    `Welcome ${uname} prepare for spam at ${email}`));
// IO('Welcome Olivia prepare for spam at olivia@tremorcontrol.net'); // 概念上的结果
```

最后，我们有两个使用 `Maybe` 的例子。由于 `chain` 在底层进行映射，如果任何值为 `null`，我们会立即停止计算。

如果这些例子一开始难以掌握，请不要担心。玩弄它们。用棍子戳它们。将它们打碎再重新组装。记住，当返回一个“普通”值时使用 `map`，当返回另一个函子时使用 `chain`。在下一章中，我们将探讨 `Applicative`，并看到一些使这类表达式更美观、更易读的好技巧。

提醒一下，这不适用于两种不同的嵌套类型。函子组合（Functor composition）以及后来的 Monad 变形器（monad transformers）可以在那种情况下帮助我们。

## 权力的滋味

容器风格的编程有时会令人困惑。我们有时会发现自己难以理解一个值嵌套在多少层容器中，或者我们需要 `map` 还是 `chain`（很快我们会看到更多的容器方法）。我们可以通过实现 `inspect` 等技巧来大大改善调试，并且我们将学习如何创建一个可以处理我们抛出的任何效果的“堆栈”，但有时我们会质疑这是否值得这么麻烦。

我想挥舞一下炽热的 Monad 之剑，来展示这种编程方式的力量。

让我们读取一个文件，然后立即上传它：

```js
// readFile :: Filename -> Either String (Task Error String) // 读取文件，可能验证失败(Either)，或异步读取失败(Task Error)
// httpPost :: Url -> String -> Task Error JSON // 发送 HTTP POST 请求，可能失败(Task Error)
// upload :: Filename -> Either String (Task Error JSON) // 组合：读取并上传
const upload = compose(map(chain(httpPost('/uploads'))), readFile);
```

在这里，我们对代码进行了几次分支。查看类型签名，我可以看到我们防范了 3 个错误——`readFile` 使用 `Either` 来验证输入（也许确保文件名存在），`readFile` 在访问文件时可能会出错，这在 `Task` 的第一个类型参数中表示，并且上传可能因任何原因失败，这由 `httpPost` 中的 `Error` 表示。我们用 `chain` 轻松地完成了两个嵌套的、顺序的异步操作。

所有这一切都是在一个线性的从左到右的流程中实现的。这完全是纯粹和声明式的。它拥有等式推导（equational reasoning）和可靠的属性。我们不必添加不必要且令人困惑的变量名。我们的 `upload` 函数是针对通用接口编写的，而不是特定的一次性 API。看在老天的份上，这只是一行该死的代码。

作为对比，让我们看看完成此操作的标准命令式方法：

```js
// upload :: Filename -> (JSON -> a) -> Void // 注意这里的回调和副作用
const upload = (filename, callback) => {
  if (!filename) {
    // 1. 同步错误处理 (throw)
    throw new Error('You need a filename!');
  } else {
    // 2. 异步操作 + 错误处理 (callback)
    readFile(filename, (errF, contents) => {
      if (errF) throw errF; // 异步错误处理 1 (throw)
      // 3. 嵌套异步操作 + 错误处理 (callback)
      httpPost('/uploads', contents, (errH, json) => {
        if (errH) throw errH; // 异步错误处理 2 (throw)
        callback(json); // 成功回调
      });
    });
  }
};
```

嗯，这难道不是魔鬼的算术吗。我们像弹珠一样在一个不稳定的疯狂迷宫中穿梭。想象一下，如果这是一个典型的应用程序，并且在此过程中还会改变变量！那我们确实就陷入了焦油坑（tar pit）。

## 理论

我们将要看的第一个定律是结合律（associativity），但也许不是你习惯的方式。

```js
// 结合律 (associativity)
compose(join, map(join)) === compose(join, join);
```

这些定律触及了 Monad 的嵌套性质，因此结合律关注的是先 join 内部类型还是外部类型以达到相同的结果。一张图片可能更具指导性：

<img src="images/monad_associativity.png" alt="monad 结合律图示" />

从左上角向下移动，我们可以先 `join` `M(M(M a))` 的外两层 `M`，然后用另一个 `join` 移到我们期望的 `M a`。或者，我们可以打开盖子，用 `map(join)` 压平内部的两层 `M`。无论我们先 join 内部还是外部的 `M`，我们最终都会得到相同的 `M a`，这就是结合律的全部意义。值得注意的是 `map(join) != join`。中间步骤的值可能不同，但最后一个 `join` 的最终结果将是相同的。

第二个定律是类似的：

```js
// 对所有 (M a) 的同一律 (identity)
compose(join, of) === compose(join, map(of)) === id;
```

它指出，对于任何 Monad `M`，`of` 和 `join` 等同于 `id`。我们也可以 `map(of)` 并从内向外攻击它。我们称之为“三角同一性”（triangle identity），因为它在可视化时呈现出这样的形状：

<img src="images/triangle_identity.png" alt="monad 同一律（三角）图示" />

如果我们从左上角向右走，我们可以看到 `of` 确实将我们的 `M a` 放入了另一个 `M` 容器中。然后如果我们向下移动并 `join` 它，我们得到的结果与一开始就调用 `id` 相同。从右向左移动，我们看到如果我们用 `map` 潜入内部并对普通的 `a` 调用 `of`，我们仍然会得到 `M (M a)`，而 `join` 会将我们带回原点。

我应该提到，我刚才写的是 `of`，然而，它必须是我们正在使用的任何 Monad 的特定 `M.of`。

现在，我以前在某个地方见过这些定律，同一律和结合律…… 等等，我在想…… 是的，当然！它们是范畴（category）的定律。但那意味着我们需要一个组合函数来完成定义。看：

```js
// Kleisli 组合
const mcompose = (f, g) => compose(chain(f), g); // f :: b -> M c, g :: a -> M b

// 左同一律 (left identity)
mcompose(M.of, f) === f; // 假设 f :: a -> M b

// 右同一律 (right identity)
mcompose(f, M.of) === f; // 假设 f :: a -> M b

// 结合律 (associativity)
mcompose(mcompose(f, g), h) === mcompose(f, mcompose(g, h)); // 假设 h :: a -> M b, g :: b -> M c, f :: c -> M d
```

它们毕竟是范畴定律。Monad 形成一个称为“Kleisli 范畴”（Kleisli category）的范畴，其中所有对象都是 Monad，而态射是链式函数（chained functions）。我不是故意用零碎的范畴论来挑逗你，而没有过多解释拼图是如何组合在一起的。目的是浅尝辄止，以展示其相关性并激发一些兴趣，同时专注于我们每天可以使用的实用属性。


## 总结

Monad 让我们能够向下钻取到嵌套的计算中。我们可以赋值变量、运行顺序效果、执行异步任务，所有这些都无需在末日金字塔（pyramid of doom）中砌一块砖。当一个值发现自己被囚禁在同一类型的多层中时，它们就来救场了。在忠实伙伴“Pointed”的帮助下，Monad 能够借给我们一个未装箱的值，并知道我们用完后能够将其放回原处。

是的，Monad 非常强大，但我们仍然发现自己需要一些额外的容器函数。例如，如果我们想一次运行一系列 API 调用，然后收集结果怎么办？我们可以用 Monad 完成这项任务，但我们必须等待每一个完成后才能调用下一个。那组合几个验证呢？我们希望继续验证以收集错误列表，但 Monad 会在第一个 `Left` 进入画面后就停止演出。

在下一章中，我们将看到 Applicative 函子如何融入容器世界，以及为什么在许多情况下我们更喜欢它们而不是 Monad。

[第十章：Applicative 函子](ch10-zh.md)


## 练习


考虑如下 User 对象：

```js
const user = {
  id: 1,
  name: 'Albert',
  address: {
    street: {
      number: 22,
      name: 'Walnut St',
    },
  },
};
```

{% exercise %}
使用 `safeProp` 和 `map/join` 或 `chain` 来安全地获取给定用户的街道名称。

{% initial src="./exercises/ch09/exercise_a.js#L16;" %}
```js
// getStreetName :: User -> Maybe String
const getStreetName = undefined; // 在这里填写你的代码
```


{% solution src="./exercises/ch09/solution_a.js" %}
{% validation src="./exercises/ch09/validation_a.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}


---


我们现在考虑以下项：

```js
// getFile :: IO String
const getFile = IO.of('/home/mostly-adequate/ch09.md'); // 获取文件路径的 IO

// pureLog :: String -> IO ()
const pureLog = str => new IO(() => console.log(str)); // 纯粹日志记录的 IO
```

{% exercise %}
使用 getFile 获取文件路径，移除目录并只保留基本名称（basename），
然后纯粹地记录它。提示：你可能需要使用 `split` 和 `last` 来从文件路径中获取基本名称。

{% initial src="./exercises/ch09/exercise_b.js#L13;" %}
```js
// logFilename :: IO ()
const logFilename = undefined; // 在这里填写你的代码

```


{% solution src="./exercises/ch09/solution_b.js" %}
{% validation src="./exercises/ch09/validation_b.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}


---

对于这个练习，我们考虑具有以下签名的辅助函数：

```js
// validateEmail :: Email -> Either String Email // 验证邮箱，返回 Either
// addToMailingList :: Email -> IO([Email]) // 将邮箱添加到邮件列表，返回 IO
// emailBlast :: [Email] -> IO () // 向整个列表发送邮件，返回 IO
```

{% exercise %}
使用 `validateEmail`、`addToMailingList` 和 `emailBlast` 创建一个函数，
如果邮箱有效，则将其添加到邮件列表，然后通知整个列表。

{% initial src="./exercises/ch09/exercise_c.js#L11;" %}
```js
// joinMailingList :: Email -> Either String (IO ())
const joinMailingList = undefined; // 在这里填写你的代码
```


{% solution src="./exercises/ch09/solution_c.js" %}
{% validation src="./exercises/ch09/validation_c.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}