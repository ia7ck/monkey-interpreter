require "minitest/autorun"

require_relative "../lib/ast"
require_relative "../lib/evaluator"
require_relative "../lib/parser"

class TestEvaluator < Minitest::Test
  def _eval(input)
    pa = Parser.new(input)
    program = pa.parse_program
    env = Environment.new
    Evaluator.evaluate(program, env)
  end

  def test_eval_integer
    tests = [
      ["1;", 1],
      ["23", 23],
      ["1; 23", 23],
      ["- 1;", -1],
      ["-23", -23],
      ["1 + -23", -22],
      ["12 * -3 / 9 - 1", -5],
      ["12 * (3 - 4) + 5;", -7],
    ]
    tests.each do |input, want|
      evaluated = _eval(input)
      _test_integer_object(want, evaluated)
    end
  end

  def _test_integer_object(want, obj)
    assert_equal(MonkeyInteger, obj.class)
    assert_equal(want, obj.value)
  end

  def test_eval_boolean
    tests = [
      ["true;", true],
      ["false", false],
      ["!false", true],
      ["!0", false],
      ["1 == 1", true],
      ["1 != 1", false],
      ["1 > 2", false],
      ["false == false", true],
      ["false != (true == false)", false],
    ]
    tests.each do |input, want|
      evaluated = _eval(input)
      _test_boolean_object(want, evaluated)
    end
  end

  def _test_boolean_object(want, obj)
    assert_equal(MonkeyBoolean, obj.class)
    assert_equal(want, obj.value)
  end

  def test_eval_string
    tests = [
      ['"abc"', "abc"],
      ['"a bc"', "a bc"],
      ['"ab " + "c"', "ab c"],
    ]
    tests.each do |input, want|
      evaluated = _eval(input)
      _test_string_object(want, evaluated)
    end
  end

  def _test_string_object(want, obj)
    assert_equal(MonkeyString, obj.class)
    assert_equal(want, obj.value)
  end

  def test_if_else_expressions
    tests = [
      ["if (true) {10}", 10],
      ["if (false) {10}", nil],
      ["if (1) {23}", 23],
      ["if (1 > 2) {34} else {5}", 5],
    ]
    tests.each do |input, want|
      evaluated = _eval(input)
      if want
        _test_integer_object(want, evaluated)
      else
        _test_null_object(evaluated)
      end
    end
  end

  def _test_null_object(obj)
    assert_equal(Evaluator::NULL, obj)
  end

  def test_let_statements
    tests = [
      ["let a = 5; a;", 5],
      ["let a = 5; let b = a * 5;", 25],
    ]
    tests.each do |input, want|
      evaluated = _eval(input)
      _test_integer_object(want, evaluated)
    end
  end

  def test_return_statements
    tests = [
      ["return 1; 2;", 1],
      [<<~EOS,
        if (true) {
          if (true) {
            return 4;
          }
          return 5;
        }
      EOS
       4],
    ]
    tests.each do |input, want|
      evaluated = _eval(input)
      _test_integer_object(want, evaluated)
    end
  end

  def test_function_object
    input = "fn(x) { x + 2; }"
    evaluated = _eval(input)
    assert_equal(1, evaluated.parameters.size)
    assert_equal("x", evaluated.parameters[0].to_str)
    assert_equal("(x + 2)", evaluated.body.to_str)
  end

  def test_apply_function
    tests = [
      ["let id = fn(x) {x;}; id(5);", 5],
      ["fn(x){x/2}(6)", 3],
      ["let id = fn(x) {return x;}; id(2);", 2],
      ["let add = fn(x, y) {x + y;}; add(1, add(2, 3));", 6],
      ["let fact = fn(n) {if (n == 0) {1} else {n * fact(n - 1)}}; fact(4);", 24],
    ]
    tests.each do |input, want|
      evaluated = _eval(input)
      _test_integer_object(want, evaluated)
    end
  end

  def test_closure
    input = <<~EOS
      let new_adder = fn(x) {
        return fn(y) {x + y}
      }
      let add_two = new_adder(2)
      add_two(3);
    EOS
    _test_integer_object(5, _eval(input))
  end

  def test_array_literals
    input = "[1, 2 * 3]"
    evaluated = _eval(input)
    assert_equal(2, evaluated.elements.size)
    _test_integer_object(1, evaluated.elements[0])
    _test_integer_object(6, evaluated.elements[1])
  end

  def test_array_index_expression
    tests = [
      ["[1, 2, 3][0]", 1],
      ["[4, 5, 6][3 - 2]", 5],
      ["[7, 8][9]", nil],
      ["[10][-3]", nil],
    ]
    tests.each do |input, want|
      evaluated = _eval(input)
      if want
        _test_integer_object(want, evaluated)
      else
        _test_null_object(evaluated)
      end
    end
  end

  def test_hash_literals
    input = '{
      "a": 1,
      "b": 1 + 1,
      "c": 6 / 2,
      4: 4,
      true: 5,
      false: 6
    }'
    wants = {
      MonkeyString.new("a") => 1,
      MonkeyString.new("b") => 2,
      MonkeyString.new("c") => 3,
      MonkeyInteger.new(4) => 4,
      MonkeyBoolean.new(true) => 5,
      MonkeyBoolean.new(false) => 6,
    }
    evaluated = _eval(input)
    wants.each do |k, v|
      _test_integer_object(v, evaluated.pairs[k].value)
    end
  end

  def test_hash_index_expressions
    tests = [
      ['{"a": 1}["a"]', 1],
      ['{"a": 1}["b"]', nil],
      ['let k = "c"; {"c": 2}[k]', 2],
      ["{}[0]", nil],
    ]
    tests.each do |input, want|
      evaluated = _eval(input)
      if want
        _test_integer_object(want, evaluated)
      else
        _test_null_object(evaluated)
      end
    end
  end

  def test_error_handling
    tests = [
      ["foobar;", "identifier not found: foobar"],
      ["fn(x, y) {} (1)", "wrong number of arguments: expected 2, given 1"],
      ['"x" - "yz"', "unknown operator: STRING - STRING"],
      ["(1 + 2)[3]", "index operator not supported INTEGER"],
      ["[1, 2][true]", "index type must be INTEGER"],
      ["{[1, 2, 3]: 4}", "unuseable as hash key: ARRAY"],
      ["{123: 4}[fn(x){x}]", "unuseable as hash key: FUNCTION"],
      ["let f = 1; f(2, 3);", "not a function: INTEGER"],
      ['len("a", "bc")', "wrong number of arguments: expected 1, given 2"],
      ["len(123)", "argument to `len` not supported, got INTEGER"],
    ]
    tests.each do |input, want_message|
      err = assert_raises(MonkeyLanguageEvaluateError) do
        _eval(input)
      end
      assert_equal(want_message, err.message)
    end
  end

  def test_builtin_functions
    # len
    tests = [
      ['len("a bc")', 4],
      ['len("")', 0],
      ["len([-1, 1])", 2],
    ]
    tests.each do |input, want|
      evaluated = _eval(input)
      _test_integer_object(want, evaluated)
    end
    # rest
    tests = [
      ["rest([1, 2, 3])", [2, 3]],
      ["rest(rest([1, 2, 3]))", [3]],
      ["rest(rest(rest([1, 2, 3])))", []],
    ]
    tests.each do |input, wants|
      evaluated = _eval(input)
      wants.zip(evaluated.elements).each do |want, got|
        _test_integer_object(want, got)
      end
    end
    input = "rest([])"
    evaluated = _eval(input)
    assert_instance_of(MonkeyNull, evaluated)
    # push
    tests = [
      ["push([1, 2], 3)", [1, 2, 3]],
      ["push([], 1)", [1]],
    ]
    tests.each do |input, wants|
      evaluated = _eval(input)
      wants.zip(evaluated.elements).each do |want, got|
        _test_integer_object(want, got)
      end
    end
  end
end
