# 第八章：容器（Tupperware）

## 万能容器

<img src="images/jar.jpg" alt="另一个罐子 - http://blog.dwinegar.com/2011/06/another-jar.html" />

我们已经看到了如何编写通过一系列纯函数来管道化（pipe）数据的程序。它们是行为的声明式规约（declarative specifications）。但是控制流（control flow）、错误处理（error handling）、异步操作（asynchronous actions）、状态（state）以及，我敢说，副作用（effects）呢？！在本章中，我们将发现构建所有这些有用的抽象（abstractions）的基础。

首先我们将创建一个容器（container）。这个容器必须能容纳任何类型的值；一个只能装木薯布丁的自封袋（ziplock）很少有用。它将是一个对象，但我们不会以面向对象（OO）的方式赋予它属性和方法。不，我们会像对待一个宝箱一样对待它——一个装载我们宝贵数据的特殊盒子。

```js
class Container {
  constructor(x) {
    this.$value = x; // 存储值的内部属性
  }

  static of(x) {
    return new Container(x); // 构造函数，用于创建 Container 实例
  }
}
```

这是我们的第一个容器。我们深思熟虑地将其命名为 `Container`。我们将使用 `Container.of` 作为构造函数，这使我们免于到处写那个糟糕的 `new` 关键字。`of` 函数的作用远不止表面看起来那么简单，但现在，你可以把它看作是将值放入我们容器的正确方式。

让我们检查一下我们全新的盒子...

```js
Container.of(3);
// Container(3)

Container.of('hotdogs');
// Container("hotdogs")

Container.of(Container.of({ name: 'yoda' }));
// Container(Container({ name: 'yoda' }))
```

如果你正在使用 node，你会看到 `{$value: x}`，尽管我们得到的是 `Container(x)`。Chrome 会正确输出类型，但这没关系；只要我们理解 `Container` 是什么样子，我们就没问题。在某些环境中，如果你愿意，可以覆盖 `inspect` 方法，但我们不会做得那么彻底。在本书中，我们将把概念上的输出写成好像我们已经覆盖了 `inspect` 一样，因为它出于教学和美观的原因，比 `{$value: x}` 更具启发性。

在我们继续之前，让我们明确几点：

*   `Container` 是一个只有一个属性的对象。很多容器只装一件东西，尽管它们不限于一件。我们随意地将其属性命名为 `$value`。
*   `$value` 不能是某一种特定类型，否则我们的 `Container` 就名不副实了。
*   一旦数据进入 `Container`，它就一直待在那里。我们*可以*通过使用 `.$value` 将其取出，但这会违背其目的。

我们这样做的原因将像梅森罐（mason jar）一样清晰，但现在，请耐心听我说。

## 我的第一个函子

一旦我们的值，无论它是什么，进入了容器，我们就需要一种方法来对它运行函数。

```js
// map :: (a -> b) -> Container a -> Container b
Container.prototype.map = function (f) {
  return Container.of(f(this.$value)); // 应用函数 f 并将结果重新包裹在 Container 中
};
```

为什么，这就像 Array 著名的方法 `map`，只是我们有 `Container a` 而不是 `[a]`。它的工作方式基本相同：

```js
Container.of(2).map(two => two + 2);
// Container(4)

Container.of('flamethrowers').map(s => s.toUpperCase());
// Container('FLAMETHROWERS')

Container.of('bombs').map(append(' away')).map(prop('length'));
// Container(10)
```

我们可以在不离开 `Container` 的情况下处理我们的值。这是一件了不起的事情。`Container` 中的值被传递给 `map` 函数，所以我们可以处理它，之后，它被返回到它的 `Container` 中以安全保管。由于从未离开 `Container`，我们可以继续 `map` 下去，随心所欲地运行函数。我们甚至可以在过程中改变类型，正如三个例子中最后一个所示。

等等，如果我们一直调用 `map`，它似乎是某种形式的组合（composition）！这里有什么数学魔法在起作用？嗯，伙计们，我们刚刚发现了*函子*（Functors）。

> 函子（Functor）是一种实现了 `map` 并遵守一些定律（laws）的类型。

是的，*函子*（Functor）只是一个带有契约的接口（interface）。我们本可以很容易地将其命名为 *Mappable*，但是，那样还有什么*乐趣*（fun）呢？函子来自范畴论（category theory），我们将在本章末尾详细研究数学，但现在，让我们致力于理解这个名字怪异的接口的直觉和实际用途。

我们到底有什么理由把一个值装起来并使用 `map` 来访问它呢？如果我们选择一个更好的问题，答案就会显现出来：让我们的容器为我们应用函数，我们能得到什么？嗯，函数应用的抽象（abstraction of function application）。当我们 `map` 一个函数时，我们要求容器类型为我们运行它。这确实是一个非常强大的概念。

## 薛定谔的 Maybe

<img src="images/cat.png" alt="酷猫，需要来源" />

`Container` 相当无聊。事实上，它通常被称为 `Identity`（同一性函子），其影响与我们的 `id` 函数大致相同（再次强调，存在数学联系，我们将在适当时机探讨）。然而，还有其他的函子，也就是具有合适的 `map` 函数的类容器类型，它们可以在映射时提供有用的行为。现在让我们定义一个。

> 一个完整的实现在[附录 B](./appendix_b.md#Maybe) 中给出

```js
class Maybe {
  static of(x) {
    return new Maybe(x);
  }

  get isNothing() {
    // 检查内部值是否为 null 或 undefined
    return this.$value === null || this.$value === undefined;
  }

  constructor(x) {
    this.$value = x;
  }

  map(fn) {
    // 如果是 Nothing，直接返回自身，否则应用函数 fn
    return this.isNothing ? this : Maybe.of(fn(this.$value));
  }

  inspect() {
    // 自定义的 inspect 方法用于显示
    return this.isNothing ? 'Nothing' : `Just(${inspect(this.$value)})`;
  }
}
```

现在，`Maybe` 看起来很像 `Container`，只有一个微小的变化：它会在调用提供的函数之前先检查它是否有一个值。这具有在我们 `map` 时避开那些讨厌的 null 的效果（注意，这个实现是为了教学而简化的）。

```js
Maybe.of('Malkovich Malkovich').map(match(/a/ig));
// Just( [ 'a', 'a' ] ) // 译者注：原文此处结果为 Just(True)，应为匹配结果数组

Maybe.of(null).map(match(/a/ig));
// Nothing // 因为初始值是 null，map 不会执行

Maybe.of({ name: 'Boris' }).map(prop('age')).map(add(10));
// Nothing // prop('age') 返回 undefined，变成 Nothing

Maybe.of({ name: 'Dinah', age: 14 }).map(prop('age')).map(add(10));
// Just(24) // prop('age') 返回 14，然后 map(add(10))
```

注意，当我们在 null 值上映射函数时，我们的应用程序不会因错误而崩溃。这是因为 `Maybe` 每次应用函数时都会注意检查值是否存在。

这种点（dot）语法是完全可以接受且函数式的，但出于第一部分提到的原因，我们希望保持我们的 pointfree 风格。碰巧的是，`map` 完全有能力委托给它接收到的任何函子：

```js
// map :: Functor f => (a -> b) -> f a -> f b
const map = curry((f, anyFunctor) => anyFunctor.map(f));
```

这令人愉快，因为我们可以像往常一样继续进行组合（composition），而 `map` 会按预期工作。ramda 的 `map` 也是如此。当具有指导意义时，我们将使用点表示法，而当方便时，则使用 pointfree 版本。你注意到了吗？我偷偷地在我们的类型签名中引入了额外的表示法。`Functor f =>` 告诉我们 `f` 必须是一个函子。这并不难，但我觉得我应该提一下。

## 使用场景

在实际应用中，我们通常会看到 `Maybe` 被用在那些可能无法返回结果的函数中。

```js
// safeHead :: [a] -> Maybe(a)
const safeHead = xs => Maybe.of(xs[0]); // 获取数组第一个元素，如果数组为空则返回 Maybe(undefined) -> Nothing

// streetName :: Object -> Maybe String
const streetName = compose(map(prop('street')), safeHead, prop('addresses')); // 从 user 对象中安全地获取第一个地址的街道名称

streetName({ addresses: [] });
// Nothing // 因为 addresses 为空，safeHead 返回 Nothing

streetName({ addresses: [{ street: 'Shady Ln.', number: 4201 }] });
// Just('Shady Ln.') // 成功获取街道名称
```

`safeHead` 就像我们普通的 `head`，但增加了类型安全性。当 `Maybe` 被引入我们的代码时，一件奇怪的事情发生了；我们被迫处理那些鬼鬼祟祟的 `null` 值。`safeHead` 函数对其可能的失败是诚实和坦率的——这没什么可耻的——所以它返回一个 `Maybe` 来告知我们这件事。然而，我们不仅仅是被*告知*，因为我们被迫使用 `map` 来获取我们想要的值，因为它被藏在 `Maybe` 对象里面。本质上，这是 `safeHead` 函数本身强制执行的 `null` 检查。我们现在可以睡得更安稳了，知道一个 `null` 值不会在我们最意想不到的时候露出它丑陋的、被斩首的头。像这样的 API 会将一个脆弱的应用程序从纸和钉子升级到木头和钉子。它们将保证更安全的软件。


有时一个函数可能会显式返回一个 `Nothing` 来表示失败。例如：

```js
// withdraw :: Number -> Account -> Maybe(Account)
const withdraw = curry((amount, { balance }) =>
  // 如果余额足够，返回 Just(更新后的账户)，否则返回 Nothing
  Maybe.of(balance >= amount ? { balance: balance - amount } : null));

// 这个函数是假设的，这里没有实现... 其他地方也没有。
// updateLedger :: Account -> Account
const updateLedger = account => account; // 假设的更新账本函数

// remainingBalance :: Account -> String
const remainingBalance = ({ balance }) => `Your balance is $${balance}`; // 显示余额的函数

// finishTransaction :: Account -> String
const finishTransaction = compose(remainingBalance, updateLedger); // 更新账本并显示余额


// getTwenty :: Account -> Maybe(String)
const getTwenty = compose(map(finishTransaction), withdraw(20)); // 取款 20 元的操作组合

getTwenty({ balance: 200.00 });
// Just('Your balance is $180') // 成功取款

getTwenty({ balance: 10.00 });
// Nothing // 余额不足，取款失败
```

如果我们现金不足，`withdraw` 会对我们嗤之以鼻并返回 `Nothing`。这个函数也传达了它的不确定性，让我们别无选择，只能对其后的所有操作进行 `map`。不同之处在于这里的 `null` 是故意的。我们得到的是 `Nothing` 而不是 `Just('..')`，用来表示失败，我们的应用程序有效地停止了运行。这一点很重要：如果 `withdraw` 失败，那么 `map` 将切断我们计算的其余部分，因为它根本不会运行被映射的函数，即 `finishTransaction`。这正是预期的行为，因为如果我们没有成功取款，我们宁愿不更新我们的账本或显示新的余额。

## 释放价值

人们经常忽略的一点是，总会有一个终点；一些产生副作用（effecting）的函数会发送 JSON，或者打印到屏幕，或者改变我们的文件系统，或者诸如此类。我们不能用 `return` 来传递输出，我们必须运行某个函数将其发送到外部世界。我们可以用禅宗公案（Zen Buddhist koan）的方式来表述：“如果一个程序没有可观察的副作用，它到底运行了吗？”。它是否为了自身的满足而正确运行？我怀疑它只是消耗了一些 CPU 周期然后又回去睡觉了...

我们应用程序的工作是检索、转换和传递数据，直到告别的时候，而执行此操作的函数可以被 `map`，因此值不必离开其容器温暖的子宫。事实上，一个常见的错误是试图以某种方式从我们的 `Maybe` 中移除值，好像里面的可能值会突然具体化，一切都会被原谅。我们必须明白，它可能是一个代码分支，我们的值不在那里去实现它的命运。我们的代码，很像薛定谔的猫，同时处于两种状态，并且应该保持这个事实直到最终的函数。这使得我们的代码即使存在逻辑分支也具有线性流程。

然而，有一个逃生舱口（escape hatch）。如果我们宁愿返回一个自定义值并继续，我们可以使用一个叫做 `maybe` 的小助手。

```js
// maybe :: b -> (a -> b) -> Maybe a -> b
const maybe = curry((v, f, m) => {
  // 如果 m 是 Nothing，返回默认值 v
  if (m.isNothing) {
    return v;
  }
  // 否则，对 m.$value 应用函数 f
  return f(m.$value);
});

// getTwenty :: Account -> String
// 使用 maybe 提供默认值，如果 withdraw 返回 Nothing
const getTwenty = compose(maybe('You\'re broke!', finishTransaction), withdraw(20));

getTwenty({ balance: 200.00 });
// 'Your balance is $180.00' // 成功，执行 finishTransaction

getTwenty({ balance: 10.00 });
// 'You\'re broke!' // 失败，返回默认值
```

我们现在要么返回一个静态值（与 `finishTransaction` 返回的类型相同），要么愉快地继续完成交易，而无需 `Maybe`。通过 `maybe`，我们见证了相当于 `if/else` 语句的东西，而对于 `map`，命令式的类比将是：`if (x !== null) { return f(x) }`。

`Maybe` 的引入可能会引起一些最初的不适。Swift 和 Scala 的用户会明白我的意思，因为它以 `Option(al)` 的名义被内置在核心库中。当被迫一直处理 `null` 检查时（有时我们绝对确定值存在），大多数人难免觉得有点费力。然而，随着时间的推移，它会成为第二天性，你可能会欣赏它的安全性。毕竟，大多数时候它会防止偷工减料并拯救我们。

编写不安全的软件就像小心翼翼地用蜡笔给每个鸡蛋涂色，然后把它们扔到车流中；就像用三只小猪警告过的材料建造养老院。将一些安全性放入我们的函数中对我们有好处，而 `Maybe` 正是帮助我们做到这一点的工具。

如果我不提一下，“真实”的实现会将 `Maybe` 分成两种类型：一种用于有值（something），另一种用于无值（nothing），那我就失职了。这使我们能够在 `map` 中遵守参数化特性（parametricity），因此像 `null` 和 `undefined` 这样的值仍然可以被映射，并且函子中值的通用限定将得到尊重。你会经常看到像 `Some(x) / None` 或 `Just(x) / Nothing` 这样的类型，而不是在 `Maybe` 中对其值进行 `null` 检查。

## 纯粹的错误处理

<img src="images/fists.jpg" alt="选一只手... 需要来源" />

这可能令人震惊，但 `throw/catch` 不太纯粹。当抛出错误时，我们不是返回一个输出值，而是拉响警报！函数发起攻击，像盾牌和长矛一样喷出成千上万的 0 和 1，在一场电子战中对抗我们入侵的输入。有了我们的新朋友 `Either`，我们可以做得比向输入宣战更好，我们可以用礼貌的消息来回应。让我们看看：

> 一个完整的实现在[附录 B](./appendix_b.md#Either) 中给出

```js
class Either {
  static of(x) {
    // 默认构造函数创建 Right 实例
    return new Right(x);
  }

  constructor(x) {
    this.$value = x;
  }
}

class Left extends Either {
  map(f) {
    // Left 实例忽略 map 操作，直接返回自身
    return this;
  }

  inspect() {
    return `Left(${inspect(this.$value)})`;
  }
}

class Right extends Either {
  map(f) {
    // Right 实例应用函数 f 并返回新的 Right 实例
    return Either.of(f(this.$value));
  }

  inspect() {
    return `Right(${inspect(this.$value)})`;
  }
}

// 辅助函数创建 Left 实例
const left = x => new Left(x);
```

`Left` 和 `Right` 是我们称为 `Either` 的抽象类型的两个子类。我跳过了创建 `Either` 超类的仪式，因为我们永远不会使用它，但了解一下是有好处的。好了，除了这两种类型之外，这里没有什么新东西。让我们看看它们的行为：

```js
Either.of('rain').map(str => `b${str}`);
// Right('brain') // Right 值被映射

left('rain').map(str => `It's gonna ${str}, better bring your umbrella!`);
// Left('rain') // Left 值被忽略

Either.of({ host: 'localhost', port: 80 }).map(prop('host'));
// Right('localhost') // Right 值被映射

left('rolls eyes...').map(prop('host'));
// Left('rolls eyes...') // Left 值被忽略
```

`Left` 是那种青少年类型，会忽略我们对其进行 `map` 的请求。`Right` 的工作方式就像 `Container`（也就是 Identity）。其威力来自于能够在 `Left` 中嵌入错误消息。

假设我们有一个可能不会成功的函数。比如我们根据出生日期计算年龄。我们可以使用 `Nothing` 来表示失败并分支我们的程序，然而，这并没有告诉我们太多信息。也许，我们想知道它为什么失败。让我们用 `Either` 来写这个。

```js
const moment = require('moment');

// getAge :: Date -> User -> Either(String, Number)
const getAge = curry((now, user) => {
  const birthDate = moment(user.birthDate, 'YYYY-MM-DD'); // 解析出生日期

  // 如果日期有效，返回 Right(年龄)，否则返回 Left(错误消息)
  return birthDate.isValid()
    ? Either.of(now.diff(birthDate, 'years'))
    : left('Birth date could not be parsed');
});

getAge(moment(), { birthDate: '2005-12-12' });
// Right(9) // 假设当前年份计算出的年龄是 9

getAge(moment(), { birthDate: 'July 4, 2001' });
// Left('Birth date could not be parsed') // 日期格式无效
```

现在，就像 `Nothing` 一样，当我们返回一个 `Left` 时，我们会短路（short-circuiting）我们的应用程序。不同的是，现在我们有了程序脱轨原因的线索。需要注意的是，我们返回 `Either(String, Number)`，它将 `String` 作为其 left 值，将 `Number` 作为其 `Right` 值。这个类型签名有点非正式，因为我们没有花时间定义一个实际的 `Either` 超类，然而，我们从类型中学到了很多。它告诉我们要么得到一个错误消息，要么得到年龄。

```js
// fortune :: Number -> String
const fortune = compose(concat('If you survive, you will be '), toString, add(1)); // 算命函数

// zoltar :: User -> Either(String, _)
// 先获取年龄，如果成功（Right），则 map(fortune)，然后 map(console.log)
const zoltar = compose(map(console.log), map(fortune), getAge(moment()));

zoltar({ birthDate: '2005-12-12' });
// 'If you survive, you will be 10' // 控制台输出
// Right(undefined) // console.log 返回 undefined

zoltar({ birthDate: 'balloons!' });
// Left('Birth date could not be parsed') // getAge 返回 Left，后续 map 被跳过
```

当 `birthDate` 有效时，程序会在屏幕上输出它神秘的命运预测供我们观看。否则，我们会得到一个 `Left`，错误消息清晰可见，尽管仍然藏在它的容器里。这就像我们抛出了一个错误一样，但是是以一种平静、温和的方式，而不是在出问题时像孩子一样发脾气尖叫。

在这个例子中，我们根据出生日期的有效性在逻辑上分支了我们的控制流，然而，它读起来像是一个从右到左的线性运动，而不是在条件语句的花括号中攀爬。通常，我们会将 `console.log` 移出我们的 `zoltar` 函数，并在调用时对其进行 `map`，但这有助于看到 `Right` 分支的不同之处。我们在右分支的类型签名中使用 `_` 来表示这是一个应该被忽略的值（在某些浏览器中，你必须使用 `console.log.bind(console)` 才能将其作为一等函数使用）。

我想借此机会指出一些你可能错过的事情：`fortune`，尽管在这个例子中与 `Either` 一起使用，但完全不知道周围有任何函子。在前面的例子中，`finishTransaction` 也是如此。在调用时，一个函数可以被 `map` 包裹，用非正式的术语来说，这将其从一个非函子函数转换为一个函子函数。我们称这个过程为*提升*（lifting）。函数通常最好处理普通数据类型而不是容器类型，然后在必要时被*提升*到正确的容器中。这导致了更简单、更可复用的函数，可以根据需要被改变以适用于任何函子。

`Either` 非常适合处理像验证（validation）这样的偶然错误，以及像丢失文件或损坏的套接字（sockets）这样更严重的、中断程序的错误。尝试用 `Either` 替换一些 `Maybe` 的例子，以提供更好的反馈。

现在，我忍不住觉得我通过仅仅将其介绍为错误消息的容器而亏待了 `Either`。它在类型中捕获了逻辑析取（logical disjunction，也就是 `||`）。它还编码了范畴论中的*余积*（Coproduct）概念，本书不会涉及，但非常值得一读，因为有可以利用的属性。它是规范的和类型（sum type，或集合的不相交并集 disjoint union of sets），因为其可能的居民（inhabitants）数量是两个包含类型的总和（我知道这有点含糊其辞，所以这里有一篇[很棒的文章](https://www.schoolofhaskell.com/school/to-infinity-and-beyond/pick-of-the-week/sum-types)）。`Either` 可以是很多东西，但作为函子，它被用于错误处理。

就像 `Maybe` 有 `maybe` 一样，我们有小写的 `either`，它的行为类似，但接收两个函数而不是一个函数和一个静态值。每个函数都应该返回相同的类型：

```js
// either :: (a -> c) -> (b -> c) -> Either a b -> c
const either = curry((f, g, e) => {
  let result;

  switch (e.constructor) {
    // 如果是 Left，应用第一个函数 f
    case Left:
      result = f(e.$value);
      break;
    // 如果是 Right，应用第二个函数 g
    case Right:
      result = g(e.$value);
      break;
    // 没有默认情况
  }

  return result;
});

// zoltar :: User -> _
// 使用 either 处理两种情况：Left 时用 id (返回错误信息)，Right 时用 fortune (计算并返回预测)
// 最后 console.log 结果
const zoltar = compose(console.log, either(id, fortune), getAge(moment()));

zoltar({ birthDate: '2005-12-12' });
// 'If you survive, you will be 10'
// undefined // console.log 的返回值

zoltar({ birthDate: 'balloons!' });
// 'Birth date could not be parsed'
// undefined // console.log 的返回值
```

终于，那个神秘的 `id` 函数派上用场了。它只是将 `Left` 中的值鹦鹉学舌般地返回，以便将错误消息传递给 `console.log`。我们通过从 `getAge` 内部强制执行错误处理，使我们的算命应用程序更加健壮。我们要么像手相师击掌一样给用户一个残酷的真相，要么继续我们的流程。就这样，我们准备好转向一种完全不同类型的函子了。

## 老麦克唐纳有副作用...

<img src="images/dominoes.jpg" alt="多米诺骨牌.. 需要来源" />

在我们关于纯粹性（purity）的章节中，我们看到了一个奇特的纯函数例子。这个函数包含一个副作用，但我们通过将其操作包装在另一个函数中，将其称为纯函数。这是另一个例子：

```js
// getFromStorage :: String -> (_ -> String)
const getFromStorage = key => () => localStorage[key]; // 返回一个函数，该函数被调用时才从 localStorage 读取
```

如果我们没有将其核心内容包裹在另一个函数中，`getFromStorage` 的输出会根据外部情况而变化。有了坚固的包装器，对于每个输入，我们总是得到相同的输出：一个函数，当被调用时，将从 `localStorage` 中检索特定的项。就像那样（也许再念叨几句圣母玛利亚保佑）我们就清除了我们的良心，一切都被原谅了。

只是，这现在不是特别有用，不是吗。就像原包装中的收藏版动作人偶，我们实际上不能玩它。要是有一种方法可以伸进容器内部并获取其内容就好了…… `IO` 登场。

```js
class IO {
  static of(x) {
    // 将值 x 包裹在一个函数中，延迟执行
    return new IO(() => x);
  }

  constructor(fn) {
    // 内部值 $value 总是一个函数
    this.$value = fn;
  }

  map(fn) {
    // 组合新函数 fn 和旧函数 this.$value
    return new IO(compose(fn, this.$value));
  }

  inspect() {
    return `IO(${inspect(this.$value)})`;
  }
}
```

`IO` 与之前的函子不同之处在于 `$value` 总是一个函数。然而，我们不将其 `$value` 视为一个函数——这是一个实现细节，我们最好忽略它。发生的事情正是我们在 `getFromStorage` 例子中看到的：`IO` 通过将其捕获在一个函数包装器中来延迟（delays）非纯操作。因此，我们将 `IO` 视为包含被包装操作的返回值，而不是包装器本身。这在 `of` 函数中很明显：我们有一个 `IO(x)`，而 `IO(() => x)` 只是为了避免求值所必需的。请注意，为了简化阅读，我们将显示包含在 `IO` 中的假设值作为结果；然而在实践中，在你实际释放副作用之前，你无法知道这个值是什么！

让我们看看它的用法：

```js
// ioWindow :: IO Window
const ioWindow = new IO(() => window); // 将获取 window 的操作包裹在 IO 中

ioWindow.map(win => win.innerWidth);
// IO(1430) // 概念上的结果，实际 $value 是一个组合后的函数

ioWindow
  .map(prop('location'))
  .map(prop('href'))
  .map(split('/'));
// IO(['http:', '', 'localhost:8000', 'blog', 'posts']) // 概念上的结果


// $ :: String -> IO [DOM]
const $ = selector => new IO(() => document.querySelectorAll(selector)); // 返回一个包裹了 DOM 查询的 IO

$('#myDiv').map(head).map(div => div.innerHTML);
// IO('I am some inner html') // 概念上的结果
```

这里，`ioWindow` 是一个我们可以立即对其进行 `map` 操作的实际 `IO`，而 `$` 是一个在被调用后返回 `IO` 的函数。我写出了*概念上的*返回值以更好地表达 `IO`，尽管实际上，它总是 `{ $value: [Function] }`。当我们对 `IO` 进行 `map` 操作时，我们将该函数放在组合的末尾，而这个组合又成为新的 `$value`，依此类推。我们映射的函数不会运行，它们会被附加到我们正在构建的计算的末尾，一个函数接一个函数，就像小心翼翼地放置我们不敢推倒的多米诺骨牌。结果让人联想到四人帮（Gang of Four）的命令模式（command pattern）或一个队列（queue）。

花点时间调动你的函子直觉。如果我们能看透实现细节，我们应该对映射任何容器感到得心应手，无论其怪癖或特质如何。我们有函子定律（functor laws），我们将在本章末尾探讨，要感谢它们赋予了我们这种伪心灵感应（pseudo-psychic）能力。无论如何，我们终于可以在不牺牲我们宝贵的纯粹性的情况下玩弄非纯值了。

现在，我们已经关住了野兽，但我们仍然需要在某个时候释放它。对我们的 `IO` 进行映射已经构建了一个强大的非纯计算，运行它肯定会打破平静。那么我们可以在哪里以及何时扣动扳机呢？有没有可能运行我们的 `IO` 并且仍然能在我们的婚礼上穿白色婚纱？答案是肯定的，如果我们把责任放在调用代码（calling code）上。我们的纯代码，尽管有邪恶的密谋和策划，仍然保持其清白，而承担实际运行副作用责任的是调用者。让我们看一个例子来具体说明这一点。

```js
// url :: IO String
const url = new IO(() => window.location.href); // 包裹获取 URL 的副作用

// toPairs :: String -> [[String]]
const toPairs = compose(map(split('=')), split('&')); // "a=1&b=2" -> [["a","1"], ["b","2"]]

// params :: String -> [[String]]
const params = compose(toPairs, last, split('?')); // 从 URL 中提取查询参数对

// findParam :: String -> IO Maybe [String]
// 在 IO 中查找特定查询参数，结果用 Maybe 包裹
const findParam = key => map(compose(Maybe.of, find(compose(eq(key), head)), params), url);

// -- 非纯的调用代码 ----------------------------------------------

// 通过调用 $value() 来运行它!
findParam('searchTerm').$value();
// Just(['searchTerm', 'wafflehouse']) // 假设 URL 包含 ?searchTerm=wafflehouse
```

我们的库通过将 `url` 包装在 `IO` 中并将责任推给调用者来保持自己的清白。你可能也注意到了我们堆叠了我们的容器；拥有一个 `IO(Maybe([x]))` 是完全合理的，它有三个函子深度（`Array` 绝对是一个可映射的容器类型）并且异常地具有表现力。

有件事一直困扰着我，我们应该立即纠正它：`IO` 的 `$value` 并不是它真正包含的值，也不是私有属性。它是手榴弹的拉环，旨在以最公开的方式被调用者拉动。让我们将这个属性重命名为 `unsafePerformIO` 来提醒我们的用户它的不稳定性。

```js
class IO {
  constructor(io) {
    // 重命名为 unsafePerformIO，明确其不安全性质
    this.unsafePerformIO = io;
  }

  map(fn) {
    return new IO(compose(fn, this.unsafePerformIO));
  }
  // ... 省略 inspect 和 of
}
```

好了，好多了。现在我们的调用代码变成了 `findParam('searchTerm').unsafePerformIO()`，这对应用程序的用户（和读者）来说清晰如昼。

`IO` 将是一个忠实的伙伴，帮助我们驯服那些野性的非纯操作。接下来，我们将看到一个精神上类似，但用途截然不同的类型。


## 异步任务

回调（Callbacks）是通往地狱的狭窄螺旋楼梯。它们是由 M.C.埃舍尔（M.C. Escher）设计的控制流。随着每个嵌套的回调被挤在花括号和圆括号构成的丛林健身房（jungle gym）之间，它们感觉就像在一个忘忧地牢（oubliette）中的炼狱（limbo）（我们还能低到什么程度？！）。光是想想它们就让我感到幽闭恐惧的寒意。别担心，我们有一种好得多处理异步代码的方式，它以“F”开头。

其内部结构有点太复杂，无法在此页面上完全展示，所以我们将使用来自 Quildreen Motta 出色的 [Folktale](https://folktale.origamitower.com/) 库的 `Data.Task`（以前是 `Data.Future`）。看一些示例用法：

```js
// -- Node readFile 示例 ------------------------------------------

const fs = require('fs');

// readFile :: String -> Task Error String
// 将 fs.readFile 包装成返回 Task 的函数
const readFile = filename => new Task((reject, result) => {
  fs.readFile(filename, 'utf-8', (err, data) => (err ? reject(err) : result(data))); // 译者注：添加了 'utf-8' 编码
});

readFile('metamorphosis.txt') // 译者注：添加了文件扩展名
  .map(split('\n'))
  .map(head);
// Task('One morning, as Gregor Samsa was waking up from anxious dreams, he discovered that in bed he had been changed into a monstrous verminous bug.') // 概念上的结果


// -- jQuery getJSON 示例 -----------------------------------------

// getJSON :: String -> {} -> Task Error JSON
// 将 $.getJSON 包装成返回 Task 的函数
const getJSON = curry((url, params) => new Task((reject, result) => {
  $.getJSON(url, params, result).fail(reject);
}));

getJSON('/video', { id: 10 }).map(prop('title'));
// Task('Family Matters ep 15') // 概念上的结果


// -- 默认最小上下文 ----------------------------------------

// 我们也可以将普通的、非未来的值放入其中
Task.of(3).map(three => three + 1);
// Task(4) // 概念上的结果
```

我称之为 `reject` 和 `result` 的函数分别是我们的错误和成功回调。如你所见，我们只需对 `Task` 进行 `map` 操作，就可以处理未来的值，就好像它就在我们手中一样。到目前为止，`map` 应该已经是老生常谈了。

如果你熟悉 Promise，你可能会认出 `map` 函数就是 `then`，而 `Task` 扮演着我们 Promise 的角色。如果你不熟悉 Promise 也不用担心，我们反正不会使用它们，因为它们不纯粹，但这个类比仍然成立。

像 `IO` 一样，`Task` 会耐心地等待我们给它绿灯信号才运行。事实上，因为它等待我们的命令，对于所有异步的事情，`IO` 实际上被 `Task` 包含（subsumed）了；`readFile` 和 `getJSON` 不需要额外的 `IO` 容器来保持纯粹。更重要的是，当我们对其进行 `map` 操作时，`Task` 以类似的方式工作：我们像把家务清单放进时间胶囊一样，为未来放置指令——一种复杂的技术性拖延行为。

要运行我们的 `Task`，我们必须调用 `fork` 方法。这就像 `unsafePerformIO` 一样工作，但顾名思义，它会分叉（fork）我们的进程，并且求值会继续进行而不会阻塞我们的线程。这可以通过线程等多种方式实现，但在这里它的行为就像普通的异步调用一样，事件循环的大轮子（event loop）会继续转动。让我们看看 `fork`：

```js
// -- 纯粹的应用代码 -------------------------------------------------
// blogPage :: Posts -> HTML
const blogPage = Handlebars.compile(blogTemplate); // 假设的 Handlebars 模板编译

// renderPage :: Posts -> HTML
const renderPage = compose(blogPage, sortBy(prop('date'))); // 排序并渲染页面

// blog :: Params -> Task Error HTML
// 获取帖子 JSON，然后渲染页面
const blog = compose(map(renderPage), getJSON('/posts'));


// -- 非纯的调用代码 ----------------------------------------------
blog({}).fork(
  // 错误处理回调
  error => $('#error').html(error.message),
  // 成功处理回调
  page => $('#main').html(page),
);

$('#spinner').show(); // 在等待异步结果时显示加载指示器
```

调用 `fork` 后，`Task` 会匆忙去查找帖子并渲染页面。与此同时，我们显示一个加载指示器，因为 `fork` 不会等待响应。最后，我们将根据 `getJSON` 调用是否成功，来显示错误或将页面渲染到屏幕上。

花点时间思考一下这里的控制流是多么线性。我们只需从下到上、从右到左地阅读，即使程序在执行期间实际上会跳跃几次。这使得阅读和推理我们的应用程序比在回调和错误处理块之间来回跳转更简单。

天哪，你看看，`Task` 也吞并了 `Either`！它必须这样做才能处理未来的失败，因为我们正常的控制流在异步世界中不适用。这都很好，因为它提供了开箱即用的充分且纯粹的错误处理。

即使有了 `Task`，我们的 `IO` 和 `Either` 函子也没有失业。请耐心看一个稍微偏向复杂和假设性，但对说明很有用的例子。

```js
// Postgres.connect :: Url -> IO DbConnection // 假设的数据库连接函数，返回 IO
// runQuery :: DbConnection -> ResultSet // 假设的运行查询函数
// readFile :: String -> Task Error String // 之前定义的读取文件 Task

// -- 纯粹的应用代码 -------------------------------------------------

// dbUrl :: Config -> Either Error Url
const dbUrl = ({ uname, pass, host, db }) => {
  // 验证配置并构建数据库 URL，用 Either 包裹结果
  if (uname && pass && host && db) {
    return Either.of(`db:pg://${uname}:${pass}@${host}5432/${db}`);
  }

  return left(Error('Invalid config!'));
};

// connectDb :: Config -> Either Error (IO DbConnection)
// 如果 dbUrl 成功，则 map(Postgres.connect)
const connectDb = compose(map(Postgres.connect), dbUrl);

// getConfig :: Filename -> Task Error (Either Error (IO DbConnection))
// 读取文件（Task），解析 JSON，然后 connectDb（返回 Either(IO)）
const getConfig = compose(map(compose(connectDb, JSON.parse)), readFile);


// -- 非纯的调用代码 ----------------------------------------------

getConfig('db.json').fork(
  // Task 失败处理（读取文件错误）
  logErr('couldn\'t read file'),
  // Task 成功处理（读取文件成功，得到 Either(IO)）
  // 使用 either 处理 Either：Left 时打印错误，Right 时 map(runQuery) 来执行 IO
  either(console.log, map(runQuery)),
);
```

在这个例子中，我们仍然在 `readFile` 的成功分支内部使用了 `Either` 和 `IO`。`Task` 处理了异步读取文件的非纯性，但我们仍然用 `Either` 处理配置验证，用 `IO` 处理数据库连接。所以你看，对于所有同步的事情，我们仍然在用它们。

我可以继续说下去，但基本上就是这些了。简单如 `map`。

在实践中，你可能会在一个工作流中有多个异步任务，我们还没有获得完整的容器 API 来处理这种情况。别担心，我们很快会研究 Monad 等，但首先，我们必须研究使这一切成为可能的数学。


## 一点理论

如前所述，函子来自范畴论并满足一些定律。让我们首先探讨这些有用的属性。

```js
// 同一律 (identity)
map(id) === id;

// 组合律 (composition)
compose(map(f), map(g)) === map(compose(f, g));
```

*同一律*很简单，但很重要。这些定律是可运行的代码片段，所以我们可以在我们自己的函子上尝试它们来验证其合法性。

```js
const idLaw1 = map(id);
const idLaw2 = id;

idLaw1(Container.of(2)); // Container(2)
idLaw2(Container.of(2)); // Container(2)
```

你看，它们是相等的。接下来让我们看看组合律。

```js
const compLaw1 = compose(map(append(' world')), map(append(' cruel')));
const compLaw2 = map(compose(append(' world'), append(' cruel')));

compLaw1(Container.of('Goodbye')); // Container('Goodbye cruel world')
compLaw2(Container.of('Goodbye')); // Container('Goodbye cruel world')
```

在范畴论中，函子将一个范畴的对象（objects）和态射（morphisms）映射到另一个范畴。根据定义，这个新范畴必须具有同一性（identity）和组合态射的能力，但我们不必检查，因为前面提到的定律确保了这些被保留。

也许我们对范畴的定义仍然有点模糊。你可以将范畴视为一个由对象以及连接它们的态射组成的网络。那么函子会将一个范畴映射到另一个范畴，而不会破坏这个网络。如果对象 `a` 在我们的源范畴 `C` 中，当我们用函子 `F` 将其映射到范畴 `D` 时，我们将该对象称为 `F a`（如果你把它们放在一起，那是什么咒语？！）。也许，看一个图表更好：

<img src="images/catmap.png" alt="范畴映射图" />

例如，`Maybe` 将我们的类型和函数的范畴映射到一个每个对象都可能不存在并且每个态射都有 `null` 检查的范畴。我们在代码中通过用 `map` 包裹每个函数，用我们的函子包裹每个类型来实现这一点。我们知道我们每个普通的类型和函数将在这个新世界中继续组合。严格来说，我们代码中的每个函子都映射到类型和函数的一个子范畴，这使得所有函子都成为一种称为自函子（endofunctors）的特殊品牌，但为了我们的目的，我们会将其视为一个不同的范畴。

我们还可以用这个图表来可视化一个态射及其对应对象的映射：

<img src="images/functormap.png" alt="函子映射图" />

除了可视化在函子 `F` 下从一个范畴到另一个范畴的映射态射之外，我们看到该图是可交换的（commutes），也就是说，如果你沿着箭头走，每条路径都会产生相同的结果。不同的路径意味着不同的行为，但我们总是到达相同的类型。这种形式化为我们提供了推理代码的有原则的方法——我们可以大胆地应用公式，而不必解析和检查每个单独的场景。让我们看一个具体的例子。

```js
// 上路 :: String -> Maybe String
const topRoute = compose(Maybe.of, reverse); // 先 reverse，再 Maybe.of

// 下路 :: String -> Maybe String
const bottomRoute = compose(map(reverse), Maybe.of); // 先 Maybe.of，再 map(reverse)

topRoute('hi'); // Just('ih')
bottomRoute('hi'); // Just('ih')
```

或者直观地看：

<img src="images/functormapmaybe.png" alt="函子映射图 Maybe 示例" />

我们可以根据所有函子都具有的属性立即看到并重构代码。

函子可以堆叠：

```js
const nested = Task.of([Either.of('pillows'), left('no sleep for you')]);
// nested 是一个 Task<Array<Either<String, String>>>

// 需要三次 map 来深入到最内层的值
map(map(map(toUpperCase)), nested);
// Task([Right('PILLOWS'), Left('no sleep for you')])
```

我们这里用 `nested` 得到的是一个未来的数组，其元素可能是错误。我们 `map` 来剥离每一层并在元素上运行我们的函数。我们看不到回调、if/else 或 for 循环；只有一个明确的上下文。然而，我们确实必须 `map(map(map(f)))`。我们可以改为组合函子。你没听错：

```js
// Functor 组合器
class Compose {
  constructor(fgx) {
    // 存储组合后的函子实例 (例如 Task(Maybe(x)))
    this.getCompose = fgx;
  }

  static of(fgx) {
    return new Compose(fgx);
  }

  map(fn) {
    // 对内部两层函子都应用 map(fn)
    return new Compose(map(map(fn), this.getCompose));
  }
}

// Task(Maybe('Rock over London'))
const tmd = Task.of(Maybe.of('Rock over London'));

// 将 Task(Maybe) 包裹在 Compose 中
const ctmd = Compose.of(tmd);

// 只需一次 map 就可以对最内层的值操作
const ctmd2 = map(append(', rock on, Chicago'), ctmd);
// Compose(Task(Just('Rock over London, rock on, Chicago')))

// 从 Compose 中取出结果
ctmd2.getCompose;
// Task(Just('Rock over London, rock on, Chicago'))
```

好了，一次 `map`。函子组合是满足结合律（associative）的，之前，我们定义了 `Container`，它实际上被称为 `Identity` 函子。如果我们有同一性（identity）和满足结合律的组合（associative composition），我们就有一个范畴。这个特殊的范畴以范畴为对象，以函子为态射，这足以让人的大脑冒汗。我们不会深入探讨这个，但欣赏一下架构上的含义，甚至只是模式中简单的抽象美感也是不错的。


## 总结

我们已经看到了几个不同的函子，但还有无限多个。一些值得注意的遗漏是可迭代的数据结构，如树、列表、映射、对等等。事件流（Event streams）和可观察对象（observables）都是函子。其他的可以用于封装，甚至只是类型建模。函子无处不在，我们将在整本书中广泛使用它们。

那么如何调用一个带有多个函子参数的函数呢？如何处理一系列有序的非纯或异步操作呢？我们还没有获得在这个盒装世界中工作的完整工具集。接下来，我们将直奔主题，研究 Monad。

[第九章：Monad 洋葱](ch09-zh.md)

## 练习

{% exercise %}
使用 `add` 和 `map` 创建一个函数，该函数增加函子内部的值。

{% initial src="./exercises/ch08/exercise_a.js#L3;" %}
```js
// incrF :: Functor f => f Int -> f Int
const incrF = undefined; // 在这里填写你的代码
```

{% solution src="./exercises/ch08/solution_a.js" %}
{% validation src="./exercises/ch08/validation_a.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}


---


给定以下 User 对象：

```js
const user = { id: 2, name: 'Albert', active: true };
```

{% exercise %}
使用 `safeProp` 和 `head` 找出用户的姓名首字母。

{% initial src="./exercises/ch08/exercise_b.js#L7;" %}
```js
// initial :: User -> Maybe String
const initial = undefined; // 在这里填写你的代码
```

{% solution src="./exercises/ch08/solution_b.js" %}
{% validation src="./exercises/ch08/validation_b.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}


---


给定以下辅助函数：

```js
// showWelcome :: User -> String
const showWelcome = compose(concat('Welcome '), prop('name')); // 显示欢迎信息

// checkActive :: User -> Either String User
const checkActive = function checkActive(user) {
  // 检查用户是否激活，返回 Either
  return user.active
    ? Either.of(user)
    : left('Your account is not active');
};
```

{% exercise %}
编写一个函数，使用 `checkActive` 和 `showWelcome` 来授予访问权限或返回错误。

{% initial src="./exercises/ch08/exercise_c.js#L15;" %}
```js
// eitherWelcome :: User -> Either String String
const eitherWelcome = undefined; // 在这里填写你的代码
```


{% solution src="./exercises/ch08/solution_c.js" %}
{% validation src="./exercises/ch08/validation_c.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}


---


我们现在考虑以下函数：

```js
// validateUser :: (User -> Either String ()) -> User -> Either String User
// 使用提供的验证函数验证用户，如果成功则返回 Right(user)
const validateUser = curry((validate, user) => validate(user).map(_ => user));

// save :: User -> IO User
// 将保存用户的操作包装在 IO 中
const save = user => new IO(() => ({ ...user, saved: true }));
```

{% exercise %}
编写一个函数 `validateName`，检查用户的名字是否超过 3 个字符，否则返回错误消息。然后使用 `either`、`showWelcome` 和 `save` 编写一个 `register` 函数，在验证成功时注册并欢迎用户。

记住 either 的两个参数必须返回相同的类型。

{% initial src="./exercises/ch08/exercise_d.js#L15;" %}
```js
// validateName :: User -> Either String ()
const validateName = undefined; // 在这里填写你的代码

// register :: User -> IO String
// 组合函数，先验证用户，然后根据结果决定是保存并显示欢迎，还是直接返回 IO(错误信息)
const register = compose(undefined, validateUser(validateName)); // 在这里填写你的代码
```


{% solution src="./exercises/ch08/solution_d.js" %}
{% validation src="./exercises/ch08/validation_d.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}