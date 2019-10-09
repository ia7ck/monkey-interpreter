require "minitest/autorun"

require "./ast"
require "./evaluator"
require "./parser"

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
      evaluated = self._eval(input)
      self._test_integer_object(want, evaluated)
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
      evaluated = self._eval(input)
      self._test_boolean_object(want, evaluated)
    end
  end

  def _test_boolean_object(want, obj)
    assert_equal(MonkeyBoolean, obj.class)
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
      evaluated = self._eval(input)
      if want
        self._test_integer_object(want, evaluated)
      else
        self._test_null_object(evaluated)
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
      evaluated = self._eval(input)
      self._test_integer_object(want, evaluated)
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
      evaluated = self._eval(input)
      self._test_integer_object(want, evaluated)
    end
  end

  def test_function_object
    input = "fn(x) { x + 2; }"
    evaluated = self._eval(input)
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
      evaluated = self._eval(input)
      self._test_integer_object(want, evaluated)
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
    self._test_integer_object(5, self._eval(input))
  end

  def test_error_handling
    tests = [
      ["foobar;", "identifier not found: foobar"],
      ["fn(x, y) {} (1)", "wrong number of arguments: expected 2, given 1"],
    ]
    tests.each do |input, want_message|
      err = assert_raises(MonkeyLanguageError) do
        self._eval(input)
      end
      assert_equal(want_message, err.message)
    end
  end
end
