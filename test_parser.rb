require "minitest/autorun"

require "./token"
require "./lexer"
require "./ast"
require "./parser"

class TestParser < Minitest::Test
  def test_parse_program
    input = <<~EOS
      let myfunc =fn(x, y){
        
      };
      let a = -123;
      let p = q + -r;
    EOS
    pa = Parser.new(input)
    program = pa.parse_program
    assert(program)
    assert_equal(3, program.statements.size)
    tests = ["myfunc", "a", "p"]
    tests.each_with_index do |name, i|
      stmt = program.statements[i]
      self._test_let_statement(stmt, name)
    end
  end

  def _test_let_statement(stmt, name)
    assert_equal("let", stmt.token_literal)
    assert_equal(name, stmt.name.token_literal)
  end

  def test_identifier_expression
    input = "foobar;"
    pa = Parser.new(input)
    program = pa.parse_program
    assert(program)
    assert_equal(1, program.statements.size)
    stmt = program.statements[0]
    assert(stmt.instance_of?(ExpressionStatement))
    assert(stmt.token)
    assert_equal(stmt.token_literal, "foobar")
    assert(stmt.expression.instance_of?(Identifier))
    assert_equal(stmt.expression.value, "foobar")
  end

  def test_integer_literal_expression
    input = "123;"
    pa = Parser.new(input)
    program = pa.parse_program
    assert(program)
    assert_equal(1, program.statements.size)
    stmt = program.statements[0]
    assert(stmt.instance_of?(ExpressionStatement))
    assert(stmt.token)
    assert_equal(stmt.token_literal, "123")
    assert(stmt.expression.instance_of?(IntegerLiteral))
    assert_equal(stmt.expression.value, 123)
  end
end
