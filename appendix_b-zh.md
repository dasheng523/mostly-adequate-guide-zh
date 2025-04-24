# 附录 B：代数结构支持

在本附录中，你会找到书中描述的各种代数结构（algebraic structures）的一些基本 JavaScript 实现。请记住，这些实现可能不是现存最快或最高效的实现；它们*仅仅是为了教学目的*。

要查找更适合生产环境的结构，请查看 [folktale](http://folktale.origamitower.com/) 或 [fantasy-land](https://github.com/fantasyland)。

注意，一些方法也引用了在[附录 A](./appendix_a.md)中定义的函数。

## Compose

```js
// curry 在附录 A 中定义
const createCompose = curry((F, G) => class Compose {
  constructor(x) {
    this.$value = x; // 存储组合后的值，例如 F(G(x))
  }

  [util.inspect.custom]() { // Node.js 的自定义 inspect 方法
    return `Compose(${inspect(this.$value)})`; // inspect 在附录 A 中定义
  }

  // ----- Pointed (Compose F G)
  static of(x) {
    // 将 x 放入 G，再放入 F，然后包裹在 Compose 中
    return new Compose(F(G(x)));
  }

  // ----- Functor (Compose F G)
  map(fn) {
    // 对内部两层函子都应用 map(fn)
    return new Compose(this.$value.map(x => x.map(fn)));
  }

  // ----- Applicative (Compose F G)
  ap(f) {
    // f 是 Compose(F(G(function)))
    // 我们需要应用 F 和 G 内部的函数
    // 这通常需要更复杂的实现，取决于 F 和 G 是否是 Applicative
    // 这里的实现可能过于简化或不正确，取决于 F 和 G 的 ap 实现
    // 一个更通用的 Applicative Compose 通常需要 F 和 G 都是 Applicative
    // return new Compose(this.$value.ap(f.$value)); // 这假设 F 和 G 的 ap 可以这样工作
    return f.map(this.$value); // 这个实现看起来不符合 Applicative Compose 的预期行为
  }
});
```


## Either

```js
class Either {
  constructor(x) {
    this.$value = x;
  }

  // ----- Pointed (Either a)
  static of(x) {
    // Either 的 'of' 总是创建一个 Right 实例
    return new Right(x);
  }
}
```

#### Left

```js
class Left extends Either {
  get isLeft() {
    return true;
  }

  get isRight() {
    return false;
  }

  static of(x) {
    // Left 不应该直接使用 of，of 是 Either 类型的方法
    throw new Error('`of` called on class Left (value) instead of Either (type)');
  }

  [util.inspect.custom]() {
    return `Left(${inspect(this.$value)})`;
  }

  // ----- Functor (Either a)
  map() {
    // Left 实例忽略 map 操作
    return this;
  }

  // ----- Applicative (Either a)
  ap() {
    // Left 实例忽略 ap 操作
    return this;
  }

  // ----- Monad (Either a)
  chain() {
    // Left 实例忽略 chain 操作
    return this;
  }

  join() {
    // Left 实例忽略 join 操作
    return this;
  }

  // ----- Traversable (Either a)
  sequence(of) {
    // 对于 Left，sequence 只是将 Left 包裹在 Applicative 上下文中
    return of(this);
  }

  traverse(of, fn) {
    // 对于 Left，traverse 直接返回包裹在 Applicative 上下文中的自身
    return of(this);
  }
}
```

#### Right

```js
class Right extends Either {
  get isLeft() {
    return false;
  }

  get isRight() {
    return true;
  }

  static of(x) {
    // Right 不应该直接使用 of，of 是 Either 类型的方法
    throw new Error('`of` called on class Right (value) instead of Either (type)');
  }

  [util.inspect.custom]() {
    return `Right(${inspect(this.$value)})`;
  }

  // ----- Functor (Either a)
  map(fn) {
    // 对 Right 的值应用 fn，并返回新的 Right
    return Either.of(fn(this.$value));
  }

  // ----- Applicative (Either a)
  ap(f) {
    // 应用 Right 内部的函数到另一个 Either (f)
    // 假设 f 是 Either(function)，通常是 Right(function)
    return f.map(this.$value);
  }

  // ----- Monad (Either a)
  chain(fn) {
    // 对 Right 的值应用函数 fn，fn 预期返回一个新的 Either
    return fn(this.$value);
  }

  join() {
    // 如果 Right 内部的值是另一个 Either，则移除一层包装
    // 这里假设 this.$value 不是 Either，直接返回值
    // 更严格的 join 实现会检查 this.$value 是否为 Either
    return this.$value;
  }

  // ----- Traversable (Either a)
  sequence(of) {
    // sequence 等价于 traverse(of, identity)
    return this.traverse(of, identity); // identity 在附录 A 中定义
  }

  traverse(of, fn) {
    // 对 Right 的值应用返回 Applicative 的函数 fn，然后将结果的结构翻转
    // fn(this.$value) 返回 F(b)，map(Either.of) 得到 F(Either b)
    return fn(this.$value).map(Either.of);
  }
}
```

## Identity

```js
class Identity {
  constructor(x) {
    this.$value = x;
  }

  [util.inspect.custom]() {
    return `Identity(${inspect(this.$value)})`;
  }

  // ----- Pointed Identity
  static of(x) {
    return new Identity(x);
  }

  // ----- Functor Identity
  map(fn) {
    // 对 Identity 的值应用 fn，并返回新的 Identity
    return Identity.of(fn(this.$value));
  }

  // ----- Applicative Identity
  ap(f) {
    // 应用 Identity 内部的函数到另一个 Identity (f)
    return f.map(this.$value);
  }

  // ----- Monad Identity
  chain(fn) {
    // 等价于 map(fn).join()
    return this.map(fn).join();
  }

  join() {
    // 移除一层 Identity 包装（如果内部值是 Identity 的话）
    // 这里假设内部值不是 Identity，直接返回值
    return this.$value;
  }

  // ----- Traversable Identity
  sequence(of) {
    return this.traverse(of, identity);
  }

  traverse(of, fn) {
    // 对 Identity 的值应用返回 Applicative 的函数 fn，然后将结果的结构翻转
    return fn(this.$value).map(Identity.of);
  }
}
```

## IO

```js
class IO {
  constructor(fn) {
    // 存储一个会产生副作用的函数
    this.unsafePerformIO = fn;
  }

  [util.inspect.custom]() {
    // IO 的内部值是函数，通常不直接显示
    return 'IO(?)';
  }

  // ----- Pointed IO
  static of(x) {
    // 将纯净值 x 包裹在一个返回它的函数中
    return new IO(() => x);
  }

  // ----- Functor IO
  map(fn) {
    // 组合新函数 fn 和旧的副作用函数
    return new IO(compose(fn, this.unsafePerformIO)); // compose 在附录 A 中定义
  }

  // ----- Applicative IO
  ap(f) {
    // 使用 chain 实现 ap
    return this.chain(fn => f.map(fn));
  }

  // ----- Monad IO
  chain(fn) {
    // 先 map(fn)，fn 返回新的 IO，然后 join
    return this.map(fn).join();
  }

  join() {
    // 返回一个新的 IO，它会先执行外层 IO，再执行内层 IO（由外层 IO 返回）
    return new IO(() => this.unsafePerformIO().unsafePerformIO());
  }
}
```

## List

```js
class List {
  constructor(xs) {
    // 存储一个数组
    this.$value = xs;
  }

  [util.inspect.custom]() {
    return `List(${inspect(this.$value)})`;
  }

  concat(x) {
    // 连接另一个 List 或数组
    return new List(this.$value.concat(x instanceof List ? x.$value : x)); // 译者注：改进了 concat 逻辑
  }

  // ----- Pointed List
  static of(x) {
    // 将单个值放入数组中创建 List
    return new List([x]);
  }

  // ----- Functor List
  map(fn) {
    // 对数组中的每个元素应用 fn
    return new List(this.$value.map(fn));
  }

  // ----- Traversable List
  sequence(of) {
    return this.traverse(of, identity);
  }

  traverse(of, fn) {
    // 对列表中的每个元素应用返回 Applicative 的函数 fn
    // 然后将 Applicative(List) 结构翻转为 List(Applicative)
    // 实现方式：使用 reduce 结合 Applicative 操作
    return this.$value.reduce(
      (fAcc, a) => fn(a).map(b => bs => bs.concat(b)).ap(fAcc), // fn(a) 返回 F b, map 得到 F (List b -> List b), ap 应用到累积的 F (List b)
      of(new List([])), // 初始累加器是 Applicative 上下文中的空 List
    );
  }
}
```


## Map

```js
class Map { // 注意：这是一个对象（字典）的封装，不是数组的 map 方法
  constructor(x) {
    // 存储一个对象
    this.$value = x;
  }

  [util.inspect.custom]() {
    return `Map(${inspect(this.$value)})`;
  }

  insert(k, v) {
    // 插入或更新键值对，返回新 Map
    const singleton = {};
    singleton[k] = v;
    return Map.of(Object.assign({}, this.$value, singleton));
  }

  reduceWithKeys(fn, zero) {
    // 使用键和值进行 reduce 操作
    return Object.keys(this.$value)
      .reduce((acc, k) => fn(acc, this.$value[k], k), zero);
  }

  // ----- Functor (Map a)
  map(fn) {
    // 对 Map 中的每个值应用 fn
    return this.reduceWithKeys(
      (m, v, k) => m.insert(k, fn(v)), // 创建新 Map 并插入映射后的值
      Map.of({}), // 译者注：修正了初始值
    );
  }

  // ----- Traversable (Map a)
  sequence(of) {
    return this.traverse(of, identity);
  }

  traverse(of, fn) {
    // 对 Map 中的每个值应用返回 Applicative 的函数 fn
    // 然后将 Applicative(Map) 结构翻转为 Map(Applicative)
    return this.reduceWithKeys(
      (fAcc, a, k) => fn(a).map(b => m => m.insert(k, b)).ap(fAcc), // fn(a) 返回 F b, map 得到 F (Map -> Map), ap 应用到累积的 F (Map)
      of(Map.of({})), // 译者注：修正了初始值
    );
  }
}
```


## Maybe

> 注意：`Maybe` 也可以用类似于我们为 `Either` 定义的方式来定义，带有 `Just` 和 `Nothing` 两个
> 子类。这只是另一种不同的风格。

```js
class Maybe {
  get isNothing() {
    // 检查内部值是否为 null 或 undefined
    return this.$value === null || this.$value === undefined;
  }

  get isJust() {
    return !this.isNothing;
  }

  constructor(x) {
    this.$value = x;
  }

  [util.inspect.custom]() {
    return this.isNothing ? 'Nothing' : `Just(${inspect(this.$value)})`;
  }

  // ----- Pointed Maybe
  static of(x) {
    return new Maybe(x);
  }

  // ----- Functor Maybe
  map(fn) {
    // 如果是 Nothing，返回自身；否则，应用 fn 并返回 Maybe.of(结果)
    return this.isNothing ? this : Maybe.of(fn(this.$value));
  }

  // ----- Applicative Maybe
  ap(f) {
    // 如果当前 Maybe 是 Nothing，返回自身；否则，应用另一个 Maybe (f) 中的函数
    return this.isNothing ? this : f.map(this.$value);
  }

  // ----- Monad Maybe
  chain(fn) {
    // 等价于 map(fn).join()
    return this.map(fn).join();
  }

  join() {
    // 如果是 Nothing，返回自身；否则，返回内部的值（移除一层 Maybe）
    return this.isNothing ? this : this.$value;
  }

  // ----- Traversable Maybe
  sequence(of) {
    return this.traverse(of, identity);
  }

  traverse(of, fn) {
    // 如果是 Nothing，返回包裹自身的 Applicative；
    // 否则，应用 fn，然后用 Maybe.of 包裹结果并返回 Applicative
    return this.isNothing ? of(this) : fn(this.$value).map(Maybe.of);
  }
}
```

## Task

```js
class Task {
  constructor(fork) {
    // 存储 'fork' 函数，该函数接收 reject 和 resolve 回调
    this.fork = fork;
  }

  [util.inspect.custom]() {
    // Task 的状态在执行前是未知的
    return 'Task(?)';
  }

  static rejected(x) {
    // 创建一个立即 reject 的 Task
    return new Task((reject, _) => reject(x));
  }

  // ----- Pointed (Task a)
  static of(x) {
    // 创建一个立即 resolve 的 Task
    return new Task((_, resolve) => resolve(x));
  }

  // ----- Functor (Task a)
  map(fn) {
    // 返回一个新的 Task，其 resolve 路径上应用了 fn
    return new Task((reject, resolve) => this.fork(reject, compose(resolve, fn)));
  }

  // ----- Applicative (Task a)
  ap(f) {
    // 使用 chain 实现 ap (可能不是最高效的并发实现)
    return this.chain(fn => f.map(fn));
  }

  // ----- Monad (Task a)
  chain(fn) {
    // 返回一个新的 Task，它会先执行当前 Task，然后将其结果传递给 fn，fn 返回一个新的 Task，最后执行这个新的 Task
    return new Task((reject, resolve) => this.fork(reject, x => fn(x).fork(reject, resolve)));
  }

  join() {
    // 移除一层 Task 包装，等价于 chain(identity)
    return this.chain(identity);
  }
}
```