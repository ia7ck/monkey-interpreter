require "minitest/autorun"

require "./token"
require "./lexer"
require "./ast"
require "./parser"

class TestParser < Minitest::Test
  def test_parse_program
    input = <<~EOS
      let myfunc =fn(x, y){
        return x+ y;
      };
      let a = -123;
      let p = q + -r;
    EOS
    pa = Parser.new(input)
    program = pa.parse_program
    assert(program)
    assert_equal(program.statements.size, 3)
    tests = ["myfunc", "a", "p"]
    tests.each_with_index do |name, i|
      stmt = program.statements[i]
      self._test_let_statement(stmt, name)
    end
  end

  def _test_let_statement(stmt, name)
    assert_equal(stmt.token_literal, "let")
    assert_equal(stmt.name.literal, name)
  end
end
