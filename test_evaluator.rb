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

  def test_error_handling
    tests = [
      ["!123", "unknown operator: !INTEGER"],
      ["1 == 2;", "unknown operator: INTEGER==INTEGER"],
      ["foobar;", "identifier not found: foobar"],
    ]
    tests.each do |input, want_message|
      err = assert_raises do
        self._eval(input)
      end
      assert_equal(want_message, err.message)
    end
  end
end
