# 第二章：一等函数

## 快速回顾
当我们说函数是“一等公民”（first class）时，我们的意思是它们就像其他值一样……换句话说，就是普通的值。我们可以像对待任何其他数据类型一样对待函数，它们并没有什么特别之处——它们可以存储在数组中，作为函数参数传递，赋值给变量，诸如此类。

这是 JavaScript 的基础知识，但值得一提，因为在 GitHub 上快速搜索代码会发现，这个概念要么被集体回避，要么就是普遍不了解。我们来看一个虚构的例子吧？好的。

```js
const hi = name => `Hi ${name}`;
const greeting = name => hi(name);
```

这里，`greeting` 中对 `hi` 的函数包装是完全冗余的。为什么？因为在 JavaScript 中函数是*可调用*（callable）的。当 `hi` 后面带有 `()` 时，它会执行并返回一个值。当它不带 `()` 时，它只是返回存储在变量中的函数本身。为了确认这一点，你自己看看：


```js
hi; // name => `Hi ${name}`
hi("jonas"); // "Hi jonas"
```

既然 `greeting` 只是用完全相同的参数来调用 `hi`，我们可以简单地写成：

```js
const greeting = hi;
greeting("times"); // "Hi times"
```

换句话说，`hi` 本身就是一个期望接收一个参数的函数，为什么还要在它外面再套一个函数，只是为了用那个该死的（bloody）相同参数来调用 `hi` 呢？这完全没有任何该死的（damn）意义。这就像在七月酷暑穿上你最厚的派克大衣，然后只是为了把空调开到最大，再要一根冰棍。

仅仅为了延迟求值（我们稍后会看到原因，这与维护有关）而用另一个函数来包裹一个函数，是令人讨厌的冗长，而且恰好也是一种不良实践。

在继续之前，对此有扎实的理解至关重要，所以让我们来看几个从 npm 包库中挖掘出来的更有趣的例子。

```js
// 无知的方式
const getServerStuff = callback => ajaxCall(json => callback(json));

// 开明的方式
const getServerStuff = ajaxCall;
```

世界上充斥着与此完全相同的 ajax 代码。以下是两者等价的原因：

```js
// 这一行
ajaxCall(json => callback(json));

// 和这一行是相同的
ajaxCall(callback);

// 所以重构 getServerStuff
const getServerStuff = callback => ajaxCall(callback);

// ...这又等价于下面这样
const getServerStuff = ajaxCall; // <-- 看，妈，没有 ()！
```

就这样，伙计们，这才是正确的做法。再来一次，这样大家就能理解我为什么如此执着了。

```js
const BlogController = {
  index(posts) { return Views.index(posts); },
  show(post) { return Views.show(post); },
  create(attrs) { return Db.create(attrs); },
  update(post, attrs) { return Db.update(post, attrs); },
  destroy(post) { return Db.destroy(post); },
};
```

这个荒谬可笑的（ridiculous）控制器 99% 都是废话。我们可以将其重写为：

```js
const BlogController = {
  index: Views.index,
  show: Views.show,
  create: Db.create,
  update: Db.update,
  destroy: Db.destroy,
};
```

……或者干脆完全废弃它，因为它除了把我们的 Views 和 Db 捆绑在一起之外，什么也没做。

## 为何偏爱一等函数？

好了，让我们深入探讨偏爱一等函数的原因。正如我们在 `getServerStuff` 和 `BlogController` 示例中看到的，很容易添加那些不提供任何附加价值的间接层（indirection），这只会增加需要维护和搜索的冗余代码量。

此外，如果这样一个不必要包装的函数必须更改，我们也必须更改我们的包装函数。

```js
httpGet('/post/2', json => renderPost(json));
```

如果 `httpGet` 发生变化，可能会发送一个 `err` 参数，那么我们就需要回去修改这些“胶水代码”。

```js
// 回到应用程序中的每个 httpGet 调用处，并显式地传递 err。
httpGet('/post/2', (json, err) => renderPost(json, err));
```

如果我们当初把它写成一等函数的形式，需要修改的地方就会少得多：

```js
// renderPost 在 httpGet 内部被调用，无论 httpGet 传递多少参数
httpGet('/post/2', renderPost);
```

除了移除不必要的函数外，（使用包装器时）我们还必须命名和引用参数。你看，命名有点问题。我们可能会遇到命名不当（misnomers）的情况——尤其是在代码库老化和需求变更时。

同一个概念有多个名称是项目中常见的混乱来源。还有通用代码的问题。例如，下面这两个函数做的事情完全相同，但其中一个感觉上通用和可复用性要强得多：

```js
// 特定于我们当前的博客
const validArticles = articles =>
  articles.filter(article => article !== null && article !== undefined),

// 对未来的项目来说，相关性强得多
const compact = xs => xs.filter(x => x !== null && x !== undefined);
```

通过使用特定的命名，我们似乎将自己与特定的数据（在这个例子中是 `articles`）绑定在了一起。这种情况经常发生，并且是许多重复造轮子的根源。

我必须提到，就像面向对象代码一样，你必须注意 `this` 会给你带来致命麻烦（bite you in the jugular）。如果底层函数使用了 `this`，而我们将其作为一等函数来调用，我们就会受到这个泄露的抽象（leaky abstraction）的怒火的影响。

```js
const fs = require('fs');

// 吓人
fs.readFile('freaky_friday.txt', Db.save);

// 不那么吓人
fs.readFile('freaky_friday.txt', Db.save.bind(Db));
```

通过将其绑定到自身，`Db` 就可以自由访问其原型链上的垃圾代码了。我像躲脏尿布一样避免使用 `this`。在编写函数式代码时，真的没必要用它。然而，在与其他库交互时，你可能不得不屈服于我们周围这个疯狂的世界。

有些人会争辩说 `this` 对于优化速度是必要的。如果你是那种沉迷于微优化（micro-optimization）的人，请合上这本书。如果你不能退款，或许可以换一本更需要精细操作（fiddly）的书。

就这些，我们准备好继续前进了。

[第三章：纯函数的纯粹快乐](ch03-zh.md)