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
    tests = ["a", "p"]
    tests.each_with_index do |name, i|
      stmt = program.statements[i]
      self._test_let_statement(stmt, name)
    end
  end

  def _test_let_statement(stmt, name)
    assert_equal("let", stmt.token_literal)
    assert_equal(name, stmt.name.token_literal)
  end

  def test_parse_identifier_expression
    input = "foobar;"
    pa = Parser.new(input)
    program = pa.parse_program
    assert(program)
    assert_equal(1, program.statements.size)
    stmt = program.statements[0]
    assert_equal(ExpressionStatement, stmt.class)
    assert(stmt.token)
    assert_equal(stmt.token_literal, "foobar")
    assert_equal(Identifier, stmt.expression.class)
    assert_equal(stmt.expression.value, "foobar")
  end

  def test_parse_integer_literal_expression
    input = "123;"
    pa = Parser.new(input)
    program = pa.parse_program
    assert(program)
    assert_equal(1, program.statements.size)
    stmt = program.statements[0]
    assert_equal(ExpressionStatement, stmt.class)
    assert(stmt.token)
    self._test_integer_literal(stmt.expression, 123)
  end

  def _test_integer_literal(integer_literal, value)
    assert_equal(IntegerLiteral, integer_literal.class)
    assert_equal(value, integer_literal.value)
    assert_equal(value.to_s, integer_literal.token_literal)
  end

  def test_parse_prefix_expressions
    prefix_test = Struct.new(:input, :operator, :integer_value)
    tests = [
      ["!777", "!", 777],
      ["-88;", "-", 88],
    ].map { |args| prefix_test.new(*args) }
    tests.each do |t|
      pa = Parser.new(t.input)
      program = pa.parse_program
      assert_equal(1, program.statements.size)
      stmt = program.statements[0]
      assert_equal(ExpressionStatement, stmt.class)
      exp = stmt.expression
      assert(exp)
      assert_equal(t.operator, exp.operator)
      self._test_integer_literal(exp.right_expression, t.integer_value)
    end
  end

  def test_parse_infix_expressions
    infix_test = Struct.new(:input, :left_value, :operator, :right_value)
    tests = [
      ["1 + 23;", 1, "+", 23],
      ["1 != 23;", 1, "!=", 23],
      ["1 < 23;", 1, "<", 23],
    ].map { |args| infix_test.new(*args) }
    tests.each do |t|
      pa = Parser.new(t.input)
      program = pa.parse_program
      assert_equal(1, program.statements.size)
      stmt = program.statements[0]
      assert_equal(ExpressionStatement, stmt.class)
      exp = stmt.expression
      assert(exp)
      self._test_integer_literal(exp.left_expression, t.left_value)
      assert_equal(t.operator, exp.operator)
      self._test_integer_literal(exp.right_expression, t.right_value)
    end
  end

  def test_operator_precedence
    tests = [
      ["1 + 2 + x;", "((1 + 2) + x)"],
      ["-a*b", "((-a) * b)"],
      ["!-a", "(!(-a))"],
      ["1 < 2 == 3 > 4", "((1 < 2) == (3 > 4))"],
      ["let p = q + -r;", "let p = (q + (-r))"],
    ]
    tests.each do |input, output|
      pa = Parser.new(input)
      program = pa.parse_program
      assert_equal(output, program.to_str)
    end
  end
end
