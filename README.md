Monkey is a programming language designed for [Writing An Interpreter In Go](https://interpreterbook.com/).

## Test
- Run all
    - `$ rake test`
- Run each file
    - `$ rake test TEST=test/test_xxx.rb`
    - e.g. `$ rake test TEST=test/test_lexer.rb`

## REPL
```sh
$ ruby lib/repr.rb
> 
```


## Monkey Language

### Variable Binding
```sh
> let a = 1;
> let b = a + 2;
> b;
3
> let a = -12;
> a;
-12
> b;
3
```

### If-Else Expression
```sh
> let a = if (1) { -1 } else { 2 };
> a;
-1
```

You can use only `if` block (without `else`). In that case, NULL object `null` may appear.

```sh
> if (123 < 45) { 6 };
null
```

The only falsy values are `false` and `null`. 

```sh
> if (0) { 12 } else { 345 };
12
```

### Function
All functions are closure in Monkey language.  
Closure is evaluated with specified environment: when the closure is defined.

```sh
> let x = 123;
> let double_x = fn() { x * 2; };
> double_x();
246
> let triple_y = fn() { y * 3; };
> let y = -45;
> triple_y();
-135
> let new_adder = fn(x) { return fn(y) { x + y }; };
> let add_two = new_adder(2);
> add_two(3);
5
> let apply_func = fn(a, b, func) { func(a, b); };
> apply_func(1, 23, fn(x, y) { x - y; });
-22
```

#### Implicit Return
Each of the following two functions returns same value `345`.
- `fn() { 345; }`
- `fn() { 12; return 345; 6; }`

### String
```sh
> let s = "hello,"
> len(s)
6
> s + " world!"
hello, world!
```

### Array
```sh
> let a = [1, 3, 5]
> len(a)
3
> a[2]
5
> a[3]
null
> push(a, 7)
[1, 3, 5, 7]
> rest(push(a, 7))
[3, 5, 7]
```

### Hash
```sh
> let h = {"k": "v", 123: [4, 5]}
> h["k"]
v
> h[123][0]
4
```

Each of

- String
- Integer
- Bool

object can be used as hash key.

### Struct
```sh
> let T = struct{"first", "second", "third"}
> let t = T{1, [2, 3]}
> t.second[0]
2
> t.third
null
```
