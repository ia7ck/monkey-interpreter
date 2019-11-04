require "minitest/autorun"

require "./token"
require "./lexer"
require "./ast"
require "./parser"

class TestParser < Minitest::Test
  def test_parse_program
    input = <<~EOS
      let a = -123;
      let p = q + -r;
    EOS
    pa = Parser.new(input)
    program = pa.parse_program
    assert(program)
    assert_equal(2, program.statements.size)
    tests = [["a", "(-123)"], ["p", "(q + (-r))"]]
    tests.each_with_index do |(name, value), i|
      stmt = program.statements[i]
      self._test_let_statement(stmt, name, value)
    end
  end

  def _parse_single_statement_program(input)
    pa = Parser.new(input)
    program = pa.parse_program
    assert(program)
    assert_equal(1, program.statements.size)
    return program.statements[0]
  end

  def _test_let_statement(stmt, name, value)
    assert_equal("let", stmt.token_literal)
    assert_equal(name, stmt.name.token_literal)
    assert_equal(value, stmt.value.to_str)
  end

  def test_return_statements
    input = "return 1; return a + b;"
    pa = Parser.new(input)
    program = pa.parse_program
    tests = ["1", "(a + b)"]
    tests.each_with_index do |want, i|
      assert_equal(want, program.statements[i].return_value.to_str)
    end
  end

  def test_parse_identifier_expression
    input = "foobar;"
    stmt = _parse_single_statement_program(input)
    assert_equal(ExpressionStatement, stmt.class)
    assert(stmt.token)
    self._test_literal_expression("foobar", stmt.expression)
  end

  def test_parse_integer_literal_expression
    input = "123;"
    stmt = _parse_single_statement_program(input)
    assert_equal(ExpressionStatement, stmt.class)
    assert(stmt.token)
    self._test_literal_expression(123, stmt.expression)
  end

  def test_parse_boolean_literal
    input = "true; false"
    pa = Parser.new(input)
    program = pa.parse_program
    assert_equal(2, program.statements.size)
    self._test_literal_expression(true, program.statements[0].expression)
    self._test_literal_expression(false, program.statements[1].expression)
  end

  def test_parse_string_literal_expression
    input = '"ab cde"'
    pa = Parser.new(input)
    program = pa.parse_program
    stmt = program.statements[0]
    self._test_literal_expression("ab cde", stmt.expression)
  end

  def _test_literal_expression(want, exp)
    case exp
    when Identifier; self._test_identifier(want, exp)
    when IntegerLiteral; self._test_integer_literal(want, exp)
    when BooleanLiteral; self._test_boolean_literal(want, exp)
    when StringLiteral; self._test_string_literal(want, exp)
    else assert(false, "type of exp not handled. got = #{exp}")
    end
  end

  def _test_identifier(value, identifier)
    assert_equal(Identifier, identifier.class)
    assert_equal(value, identifier.value)
    assert_equal(value, identifier.token_literal)
  end

  def _test_integer_literal(value, integer_literal)
    assert_equal(IntegerLiteral, integer_literal.class)
    assert_equal(value, integer_literal.value)
    assert_equal(value.to_s, integer_literal.token_literal)
  end

  def _test_boolean_literal(value, boolean_literal)
    assert_equal(BooleanLiteral, boolean_literal.class)
    assert_equal(value, boolean_literal.value)
    assert_equal(value.to_s, boolean_literal.token_literal)
  end

  def _test_string_literal(value, string_literal)
    assert_equal(StringLiteral, string_literal.class)
    assert_equal(value, string_literal.value)
    assert_equal(value.to_s, string_literal.token_literal)
  end

  def test_if_expression
    input = "if (x < y) {x};"
    stmt = _parse_single_statement_program(input)
    exp = stmt.expression
    self._test_infix_expression("x", "<", "y", exp.condition)
    assert_equal(1, exp.consequence.statements.size)
    self._test_identifier("x", exp.consequence.statements[0].expression)
    assert_nil(exp.alternative)
  end

  def test_if_else_expression
    input = "if (x < y) {x} else {y}"
    stmt = _parse_single_statement_program(input)
    alt = stmt.expression.alternative
    self._test_identifier("y", alt.statements[0].expression)
  end

  def test_parse_function_literal
    input = "fn(x, y) { x + y; };"
    stmt = _parse_single_statement_program(input)
    assert_equal(FunctionLiteral, stmt.expression.class)
    fl = stmt.expression
    assert_equal(2, fl.parameters.size)
    assert_equal(1, fl.body.statements.size)
    body_stmt = fl.body.statements[0]
    assert_equal(ExpressionStatement, body_stmt.class)
    self._test_infix_expression("x", "+", "y", body_stmt.expression)
  end

  def test_parse_function_parameters
    tests = [
      ["fn() {};", []],
      ["fn(x) {}", ["x"]],
      ["fn(x, y, z) {}", ["x", "y", "z"]],
    ]
    tests.each do |input, wants|
      stmt = _parse_single_statement_program(input)
      fl = stmt.expression
      params = fl.parameters
      assert_equal(wants.size, params.size)
      wants.zip(params).each do |want, param|
        self._test_identifier(want, param)
      end
    end
  end

  def test_parse_prefix_expressions
    tests = [
      ["!777", "!", 777],
      ["-88;", "-", 88],
    ]
    tests.each do |input, operator, integer_value|
      stmt = _parse_single_statement_program(input)
      assert_equal(ExpressionStatement, stmt.class)
      exp = stmt.expression
      assert(exp)
      assert_equal(operator, exp.operator)
      self._test_literal_expression(integer_value, exp.right_expression)
    end
  end

  def test_parse_infix_expressions
    tests = [
      ["1 + 23;", 1, "+", 23],
      ["1 != 23;", 1, "!=", 23],
      ["1 < 23;", 1, "<", 23],
    ]
    tests.each do |input, left_value, operator, right_value|
      stmt = _parse_single_statement_program(input)
      assert_equal(ExpressionStatement, stmt.class)
      exp = stmt.expression
      assert(exp)
      self._test_infix_expression(left_value, operator, right_value, exp)
    end
  end

  def _test_infix_expression(left, operator, right, exp)
    assert_equal(InfixExpression, exp.class)
    self._test_literal_expression(left, exp.left_expression)
    assert_equal(operator, exp.operator)
    self._test_literal_expression(right, exp.right_expression)
  end

  def test_parse_call_expression
    input = "add(a, 2 * 3, 4 + 5);"
    stmt = _parse_single_statement_program(input)
    exp = stmt.expression
    self._test_literal_expression("add", exp.function)
    args = exp.arguments
    assert_equal(3, args.size)
    self._test_literal_expression("a", args[0])
    self._test_infix_expression(2, "*", 3, args[1])
    self._test_infix_expression(4, "+", 5, args[2])
  end

  def test_parse_call_arguments
    tests = [
      ["f();", []],
      ["f(x * y)", ["(x * y)"]],
      ["f(x + 1, -y, g(x, y))", ["(x + 1)", "(-y)", "g(x, y)"]],
    ]
    tests.each do |input, wants|
      stmt = _parse_single_statement_program(input)
      exp = stmt.expression
      args = exp.arguments
      assert_equal(wants.size, args.size)
      wants.zip(args).each do |want, arg|
        assert_equal(want, arg.to_str)
      end
    end
  end

  def test_parse_array_literals
    tests = [
      ["[x + 1, -y, g(x, y)]", ["(x + 1)", "(-y)", "g(x, y)"]],
      ["[1, []]", ["1", "[]"]],
    ]
    tests.each do |input, wants|
      stmt = _parse_single_statement_program(input)
      exp = stmt.expression
      elems = exp.elements
      assert_equal(wants.size, elems.size)
      wants.zip(elems).each do |want, elem|
        assert_equal(want, elem.to_str)
      end
    end
  end

  def test_operator_precedence
    tests = [
      [
        "1 + 2 + x; a+b",
        "((1 + 2) + x) (a + b)",
      ],
      ["1 * (2 + x);", "(1 * (2 + x))"],
      ["-a*b", "((-a) * b)"],
      ["!-a", "(!(-a))"],
      ["1 < 2 == 3 > 4", "((1 < 2) == (3 > 4))"],
      ["let p = q + -r;", "let p = (q + (-r))"],
      ["a + add(b * c)  - d", "((a + add((b * c))) - d)"],
      ["a * [1, 2][3 * 4] * b", "((a * ([1, 2][(3 * 4)])) * b)"],
      ["5 * [4, 3, 2][1] * 0", "((5 * ([4, 3, 2][1])) * 0)"],
    ]
    tests.each do |input, output|
      pa = Parser.new(input)
      program = pa.parse_program
      assert_equal(output, program.to_str)
    end
  end
end
