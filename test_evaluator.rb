require "minitest/autorun"

require "./ast"
require "./evaluator"
require "./parser"

class TestEvaluator < Minitest::Test
  def test_eval_integer
    tests = [
      ["1;", 1],
      ["23", 23],
      ["- 1;", -1],
      ["-23", -23],
      ["1 + -23", -22],
      ["12 * -3 / 9 - 1", -5],
    ]
    tests.each do |input, want_value|
      evaluated = self._eval(input)
      self._test_integer_object(evaluated, want_value)
    end
  end

  def _eval(input)
    pa = Parser.new(input)
    program = pa.parse_program
    Evaluator.evaluate(program)
  end

  def _test_integer_object(obj, want_value)
    assert_equal(MonkeyInteger, obj.class)
    assert_equal(want_value, obj.value)
  end
end
