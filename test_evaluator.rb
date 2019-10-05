require "minitest/autorun"

require "./ast"
require "./evaluator"
require "./parser"

class TestEvaluator < Minitest::Test
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
    tests.each do |input, want_value|
      evaluated = self._eval(input)
      self._test_integer_object(evaluated, want_value)
    end
  end

  def _eval(input)
    pa = Parser.new(input)
    program = pa.parse_program
    env = Environment.new
    Evaluator.evaluate(program, env)
  end

  def _test_integer_object(obj, want_value)
    assert_equal(MonkeyInteger, obj.class)
    assert_equal(want_value, obj.value)
  end

  def test_let_statements
    tests = [
      ["let a = 5; a;", 5],
      ["let a = 5; let b = a * 5;", 25],
    ]
    tests.each do |input, want_value|
      evaluated = self._eval(input)
      self._test_integer_object(evaluated, want_value)
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
      # ["let id = fn(x) {return x;}; id(5);", 5], # TODO
      ["let add = fn(x, y) {x + y;}; add(1, add(2, 3));", 6],
    ]
    tests.each do |input, want|
      evaluated = self._eval(input)
      self._test_integer_object(evaluated, want)
    end
  end

  def test_closure
    input = <<~EOS
      let new_adder = fn(x) {
        fn(y) {x + y}
      }
      let add_two = new_adder(2)
      add_two(3);
    EOS
    self._test_integer_object(self._eval(input), 5)
  end

  def test_error_handling
    tests = [
      ["!123", "unknown operator: !INTEGER"],
      ["1 == 2;", "unknown operator: INTEGER==INTEGER"],
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
