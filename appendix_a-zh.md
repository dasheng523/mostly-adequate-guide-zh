# 附录 A：必要的函数支持

在本附录中，你会找到书中描述的各种函数的一些基本 JavaScript 实现。请记住，这些实现可能不是现存最快或最高效的实现；它们*仅仅是为了教学目的*。

要查找更适合生产环境的函数，请查看 [ramda](https://ramdajs.com/)、[lodash](https://lodash.com/) 或 [folktale](http://folktale.origamitower.com/)。

注意，一些函数也引用了在[附录 B](./appendix_b.md)中定义的代数结构（algebraic structures）。

## always

```js
// always :: a -> b -> a
const always = curry((a, b) => a);
```


## compose

```js
// compose :: ((y -> z), (x -> y),  ..., (a -> b)) -> a -> z
const compose = (...fns) => (...args) => fns.reduceRight((res, fn) => [fn.call(null, ...res)], args)[0];
```


## curry

```js
// curry :: ((a, b, ...) -> c) -> a -> b -> ... -> c
function curry(fn) {
  const arity = fn.length; // 获取函数期望的参数数量

  return function $curry(...args) {
    // 如果传入的参数数量少于期望数量，返回一个绑定了当前参数的新函数
    if (args.length < arity) {
      return $curry.bind(null, ...args);
    }

    // 如果参数足够，则调用原函数
    return fn.call(null, ...args);
  };
}
```


## either

```js
// either :: (a -> c) -> (b -> c) -> Either a b -> c
const either = curry((f, g, e) => {
  // 检查 Either 实例是 Left 还是 Right
  if (e.isLeft) {
    // 如果是 Left，应用第一个函数 f
    return f(e.$value);
  }

  // 如果是 Right，应用第二个函数 g
  return g(e.$value);
});
```


## identity

```js
// identity :: x -> x
const identity = x => x;
```


## inspect

```js
// inspect :: a -> String // 用于生成值的字符串表示，方便调试
const inspect = (x) => {
  // 如果对象有自己的 inspect 方法，则调用它
  if (x && typeof x.inspect === 'function') {
    return x.inspect();
  }

  // 检查函数
  function inspectFn(f) {
    return f.name ? f.name : f.toString();
  }

  // 检查普通值
  function inspectTerm(t) {
    switch (typeof t) {
      case 'string':
        return `'${t}'`; // 字符串加上引号
      case 'object': {
        // 递归检查对象属性
        const ts = Object.keys(t).map(k => [k, inspect(t[k])]);
        return `{${ts.map(kv => kv.join(': ')).join(', ')}}`; // 格式化为 {key: value, ...}
      }
      default:
        return String(t); // 其他类型直接转字符串
    }
  }

  // 检查参数（可能是数组或单个值）
  function inspectArgs(args) {
    return Array.isArray(args) ? `[${args.map(inspect).join(', ')}]` : inspectTerm(args);
  }

  // 根据类型调用不同的检查函数
  return (typeof x === 'function') ? inspectFn(x) : inspectArgs(x);
};
```


## left

```js
// left :: a -> Either a b
const left = a => new Left(a); // 创建 Left 实例的辅助函数
```


## liftA2

```js
// liftA2 :: (Applicative f) => (a1 -> a2 -> b) -> f a1 -> f a2 -> f b
const liftA2 = curry((fn, a1, a2) => a1.map(fn).ap(a2)); // 将二元函数提升到 Applicative 函子上
```


## liftA3

```js
// liftA3 :: (Applicative f) => (a1 -> a2 -> a3 -> b) -> f a1 -> f a2 -> f a3 -> f b
const liftA3 = curry((fn, a1, a2, a3) => a1.map(fn).ap(a2).ap(a3)); // 将三元函数提升到 Applicative 函子上
```


## maybe

```js
// maybe :: b -> (a -> b) -> Maybe a -> b
const maybe = curry((v, f, m) => {
  // 检查 Maybe 实例是否为 Nothing
  if (m.isNothing) {
    // 如果是 Nothing，返回默认值 v
    return v;
  }

  // 如果是 Just，对其内部值应用函数 f
  return f(m.$value);
});
```


## nothing

```js
// nothing :: Maybe a
const nothing = Maybe.of(null); // Maybe 的 Nothing 实例
```


## reject

```js
// reject :: a -> Task a b
const reject = a => Task.rejected(a); // 创建一个 rejected 状态的 Task
```