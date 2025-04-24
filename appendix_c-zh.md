好的，这是附录 C 的翻译：

# 附录 C：Pointfree 工具函数

在本附录中，你会找到书中描述的一些相当经典的 JavaScript 函数的 Pointfree 风格的版本。以下所有函数都可以在练习中使用，作为全局上下文的一部分。请记住，这些实现可能不是现存最快或最高效的实现；它们*仅用于教学目的*。

要查找更适合生产环境使用的函数，请查看 [ramda](https://ramdajs.com/)、[lodash](https://lodash.com/) 或 [folktale](http://folktale.origamitower.com/)。

请注意，这些函数引用了在[附录 A](./appendix_a.md)中定义的 `curry` 和 `compose` 函数。

## add

```js
// add :: Number -> Number -> Number
const add = curry((a, b) => a + b);
```

## append

```js
// append :: String -> String -> String
const append = flip(concat); // 使用 flip 交换 concat 的参数顺序
```

## chain

```js
// chain :: Monad m => (a -> m b) -> m a -> m b
const chain = curry((fn, m) => m.chain(fn)); // Monad 的 chain 方法的柯里化版本
```

## concat

```js
// concat :: String -> String -> String
const concat = curry((a, b) => a.concat(b)); // 连接两个字符串
```

## eq

```js
// eq :: Eq a => a -> a -> Boolean
const eq = curry((a, b) => a === b); // 检查两个值是否严格相等
```

## filter

```js
// filter :: (a -> Boolean) -> [a] -> [a]
const filter = curry((fn, xs) => xs.filter(fn)); // 数组的 filter 方法的柯里化版本
```

## flip

```js
// flip :: (a -> b -> c) -> b -> a -> c
const flip = curry((fn, a, b) => fn(b, a)); // 交换函数的前两个参数的顺序
```

## forEach

```js
// forEach :: (a -> ()) -> [a] -> ()
const forEach = curry((fn, xs) => xs.forEach(fn)); // 数组的 forEach 方法的柯里化版本
```

## head

```js
// head :: [a] -> a
const head = xs => xs[0]; // 获取数组的第一个元素
```

## intercalate

```js
// intercalate :: String -> [String] -> String
const intercalate = curry((str, xs) => xs.join(str)); // 使用指定分隔符连接字符串数组
```

## join

```js
// join :: Monad m => m (m a) -> m a
const join = m => m.join(); // Monad 的 join 方法
```

## last

```js
// last :: [a] -> a
const last = xs => xs[xs.length - 1]; // 获取数组的最后一个元素
```

## map

```js
// map :: Functor f => (a -> b) -> f a -> f b
const map = curry((fn, f) => f.map(fn)); // Functor 的 map 方法的柯里化版本
```

## match

```js
// match :: RegExp -> String -> Boolean
const match = curry((re, str) => re.test(str)); // 使用正则表达式测试字符串
```

## prop

```js
// prop :: String -> Object -> a
const prop = curry((p, obj) => obj[p]); // 获取对象的指定属性
```

## reduce

```js
// reduce :: (b -> a -> b) -> b -> [a] -> b
const reduce = curry((fn, zero, xs) => xs.reduce(fn, zero)); // 数组的 reduce 方法的柯里化版本
```

## replace

```js
// replace :: RegExp -> String -> String -> String
const replace = curry((re, rpl, str) => str.replace(re, rpl)); // 字符串的 replace 方法的柯里化版本
```

## reverse

```js
// reverse :: [a] -> [a]
const reverse = x => (Array.isArray(x) ? x.reverse() : x.split('').reverse().join('')); // 反转数组或字符串
```

## safeHead

```js
// safeHead :: [a] -> Maybe a
const safeHead = compose(Maybe.of, head); // 安全地获取数组头部，返回 Maybe
```

## safeLast

```js
// safeLast :: [a] -> Maybe a
const safeLast = compose(Maybe.of, last); // 安全地获取数组尾部，返回 Maybe
```

## safeProp

```js
// safeProp :: String -> Object -> Maybe a
const safeProp = curry((p, obj) => compose(Maybe.of, prop(p))(obj)); // 安全地获取对象属性，返回 Maybe
```

## sequence

```js
// sequence :: (Applicative f, Traversable t) => (a -> f a) -> t (f a) -> f (t a)
const sequence = curry((of, f) => f.sequence(of)); // Traversable 的 sequence 方法的柯里化版本
```

## sortBy

```js
// sortBy :: Ord b => (a -> b) -> [a] -> [a]
const sortBy = curry((fn, xs) => xs.slice().sort((a, b) => { // 译者注：添加 slice() 避免修改原数组
  const fa = fn(a); // 译者注：缓存 fn(a) 和 fn(b)
  const fb = fn(b);
  if (fa === fb) {
    return 0;
  }

  return fa > fb ? 1 : -1;
})); // 根据函数结果对数组进行排序
```

## split

```js
// split :: String -> String -> [String]
const split = curry((sep, str) => str.split(sep)); // 字符串的 split 方法的柯里化版本
```

## take

```js
// take :: Number -> [a] -> [a]
const take = curry((n, xs) => xs.slice(0, n)); // 获取数组的前 n 个元素
```

## toLowerCase

```js
// toLowerCase :: String -> String
const toLowerCase = s => s.toLowerCase(); // 将字符串转换为小写
```

## toString

```js
// toString :: a -> String
const toString = String; // 将值转换为字符串
```

## toUpperCase

```js
// toUpperCase :: String -> String
const toUpperCase = s => s.toUpperCase(); // 将字符串转换为大写
```

## traverse

```js
// traverse :: (Applicative f, Traversable t) => (a -> f a) -> (a -> f b) -> t a -> f (t b)
const traverse = curry((of, fn, f) => f.traverse(of, fn)); // Traversable 的 traverse 方法的柯里化版本
```

## unsafePerformIO

```js
// unsafePerformIO :: IO a -> a
const unsafePerformIO = io => io.unsafePerformIO(); // 执行 IO 操作获取其结果
```