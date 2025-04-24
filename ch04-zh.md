# 第四章：柯里化

## 如果生活中没有你，我无法生存
我父亲曾经解释说，有些东西在拥有之前，人是可以没有它们也能活下去的。微波炉就是其中之一。智能手机是另一个。我们当中年纪大一些的人会记得没有互联网的充实生活。对我来说，柯里化（Currying）就在这个列表上。

这个概念很简单：你可以用比函数期望的更少的参数来调用它。它会返回一个接收余下参数的函数。

你可以选择一次性调用它，或者只是逐个传入参数。

```js
const add = x => y => x + y;
const increment = add(1);
const addTen = add(10);

increment(2); // 3
addTen(2); // 12
```

这里我们创建了一个函数 `add`，它接收一个参数并返回一个函数。通过调用它，返回的函数通过闭包（closure）记住了第一个参数。然而，一次性用所有参数调用它有点麻烦，所以我们可以使用一个名为 `curry` 的特殊辅助函数，来让定义和调用这样的函数更容易。

让我们设置几个柯里化函数来玩玩。从现在开始，我们将调用我们在[附录 A - 必要的函数支持](./appendix_a.md)中定义的 `curry` 函数。

```js
const match = curry((what, s) => s.match(what));
const replace = curry((what, replacement, s) => s.replace(what, replacement));
const filter = curry((f, xs) => xs.filter(f));
const map = curry((f, xs) => xs.map(f));
```

我遵循的模式很简单，但很重要。我策略性地将我们操作的数据（字符串 String，数组 Array）放在了最后一个参数的位置。使用时就会明白为什么了。

(语法 `/r/g` 是一个正则表达式（regular expression），意思是_匹配所有字母 'r'_。如果你愿意，可以阅读[更多关于正则表达式的内容](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions)。)

```js
match(/r/g, 'hello world'); // [ 'r' ] // 匹配字符串中的 /r/g

const hasLetterR = match(/r/g); // 返回一个函数：x => x.match(/r/g)
hasLetterR('hello world'); // [ 'r' ]
hasLetterR('just j and s and t etc'); // null

filter(hasLetterR, ['rock and roll', 'smooth jazz']); // ['rock and roll'] // 使用 hasLetterR 过滤数组

const removeStringsWithoutRs = filter(hasLetterR); // 返回一个函数：xs => xs.filter(x => x.match(/r/g))
removeStringsWithoutRs(['rock and roll', 'smooth jazz', 'drum circle']); // ['rock and roll', 'drum circle']

const noVowels = replace(/[aeiou]/ig); // 返回一个函数：(r,x) => x.replace(/[aeiou]/ig, r)
const censored = noVowels('*'); // 返回一个函数：x => x.replace(/[aeiou]/ig, '*')
censored('Chocolate Rain'); // 'Ch*c*l*t* R**n'
```

这里演示的是能够通过一两个参数来“预加载”一个函数，从而得到一个记住了这些参数的新函数。

我鼓励你克隆 Mostly Adequate 的仓库 (`git clone
https://github.com/MostlyAdequate/mostly-adequate-guide.git`)，复制上面的代码，然后在 REPL 中尝试一下。`curry` 函数，以及附录中定义的任何东西，都可以在 `support/index.js` 模块中找到。

或者，查看 `npm` 上发布的版本：

```
npm install @mostly-adequate/support
```

## 不只是文字游戏 / 特别的佐料

柯里化在很多方面都很有用。我们可以仅仅通过给我们基础函数一些参数来创建新函数，正如在 `hasLetterR`、`removeStringsWithoutRs` 和 `censored` 中看到的那样。

我们也有能力将任何处理单个元素的函数，通过用 `map` 包装它，转换成处理数组的函数：

```js
const getChildren = x => x.childNodes; // 获取子节点
const allTheChildren = map(getChildren); // 创建一个处理数组的函数，对每个元素调用 getChildren
```

给函数提供比它期望的少的参数通常称为*部分应用*（partial application）。部分应用一个函数可以消除很多样板代码（boiler plate code）。考虑一下如果使用 lodash 中未柯里化（uncurried）的 `map`（注意参数顺序不同），上面的 `allTheChildren` 函数会是什么样子：

```js
const allTheChildren = elements => map(elements, getChildren);
```

我们通常不定义处理数组的函数，因为我们可以直接内联调用 `map(getChildren)`。对于 `sort`、`filter` 和其他高阶函数（*高阶函数*（higher order function）是接收或返回函数的函数）也是如此。

当我们谈论*纯函数*（pure functions）时，我们说它们接收 1 个输入，产生 1 个输出。柯里化正是这样做的：每个单独的参数都返回一个期望接收剩余参数的新函数。那，老伙计，就是 1 个输入对应 1 个输出。

无论输出是否是另一个函数——它都符合纯函数的条件。我们确实允许一次传递多个参数，但这仅仅被视为为了方便而省略额外的 `()`。


## 总结

柯里化非常方便，我非常享受每天使用柯里化函数的工作。它是工具箱中的一个工具，使得函数式编程不那么冗长和乏味。

我们可以仅仅通过传入几个参数就动态地创建新的、有用的函数，并且还有一个额外的好处，尽管有多个参数，我们仍然保留了数学函数的定义。

让我们获取另一个必不可少的工具，叫做 `compose`。

[第五章：通过组合进行编码](ch05-zh.md)

## 练习

#### 关于练习的说明

在整本书中，你可能会遇到像这样的“练习”部分。如果你正在从 [gitbook](https://mostly-adequate.gitbooks.io/mostly-adequate-guide)（推荐）阅读，练习可以直接在浏览器中完成。

请注意，对于本书的所有练习，全局作用域中总是有一些辅助函数可供你使用。因此，在[附录 A](./appendix_a.md)、[附录 B](./appendix_b.md) 和 [附录 C](./appendix_c.md) 中定义的任何内容都可供你使用！而且，仿佛这还不够，一些练习还会定义特定于它们所呈现的问题的函数；事实上，也请将它们视为可用。

> 提示：你可以在嵌入式编辑器中使用 `Ctrl + Enter` 提交你的解决方案！

#### 在你的机器上运行练习（可选）

如果你更喜欢使用自己的编辑器直接在文件中做练习：

- 克隆仓库 (`git clone git@github.com:MostlyAdequate/mostly-adequate-guide.git`)
- 进入 *exercises* 部分 (`cd mostly-adequate-guide/exercises`)
- 确保你使用的是推荐的 node 版本 v10.22.1（例如 `nvm install`）。更多相关信息请参见[本书的 readme](./README.md#about-the-nodejs-version)
- 使用 [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) 安装必要的工具 (`npm install`)
- 通过修改相应章节文件夹中名为 *exercise\_\** 的文件来完成答案
- 使用 npm 运行校正（例如 `npm run ch04`）

单元测试（Unit tests）将针对你的答案运行，并在出错时提供提示。顺便说一下，练习的答案在名为 *solution\_\** 的文件中。

#### 让我们练习吧！

{% exercise %}
通过部分应用函数来重构，移除所有参数。

{% initial src="./exercises/ch04/exercise_a.js#L3;" %}
```js
const words = str => split(' ', str);
```

{% solution src="./exercises/ch04/solution_a.js" %}
{% validation src="./exercises/ch04/validation_a.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}


---


{% exercise %}
通过部分应用函数来重构，移除所有参数。

{% initial src="./exercises/ch04/exercise_b.js#L3;" %}
```js
const filterQs = xs => filter(x => match(/q/i, x), xs);
```

{% solution src="./exercises/ch04/solution_b.js" %}
{% validation src="./exercises/ch04/validation_b.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}


---


考虑以下函数：

```js
const keepHighest = (x, y) => (x >= y ? x : y);
```

{% exercise %}
使用辅助函数 `keepHighest` 重构 `max`，使其不引用任何参数。

{% initial src="./exercises/ch04/exercise_c.js#L7;" %}
```js
const max = xs => reduce((acc, x) => (x >= acc ? x : acc), -Infinity, xs);
```

{% solution src="./exercises/ch04/solution_c.js" %}
{% validation src="./exercises/ch04/validation_c.js" %}
{% context src="./exercises/support.js" %}
{% endexercise %}