Monkey is a programming language designed for [Writing An Interpreter In Go](https://interpreterbook.com/).

## Test
- Run all
    - `$ rake test`
- Run each file
    - `$ rake test TEST=test_xxx.rb`
    - e.g. `$ rake test TEST=test_lexer.rb`

## REPL
```sh
$ ruby repr.rb
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
> let a = if(1) { -1 } else { 2 };
> a;
-1
```

You can use only `if` block (without `else`). In that case, NULL object `null` may appear.

```sh
> if(123 < 45) { 6 };
null
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
-90
> let new_adder = fn(x) { fn(y) { x + y }; };
> let add_two = new_adder(2);
> add_two(3);
5
> let apply_func = fn(a, b, func) { func(a, b); };
> apply_func(1, 23, fn(x, y) { x - y; });
-22
```
