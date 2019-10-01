require "minitest/autorun"

require "./token"
require "./lexer"

class TestLexer < Minitest::Test
  def test_read_token
    input = <<~EOS
      let myfunc =fn(x, y){
        return x+ y;
      };
    EOS
    le = Lexer.new(input)
    tests = [
      [Token::LET, "let"],
      [Token::IDENT, "myfunc"],
      [Token::ASSIGN, "="],
      [Token::FUNCTION, "fn"],
      [Token::LPAR, "("],
      [Token::IDENT, "x"],
      [Token::COMMA, ","],
      [Token::IDENT, "y"],
      [Token::RPAR, ")"],
      [Token::LBRACE, "{"],
      [Token::IDENT, "return"],
      [Token::IDENT, "x"],
      [Token::PLUS, "+"],
      [Token::IDENT, "y"],
      [Token::SEMICOLON, ";"],
      [Token::RBRACE, "}"],
      [Token::SEMICOLON, ";"],
      [Token::EOF, "$"],
    ]
    tests.each do |t, l|
      token = le.read_token
      assert_equal(t, token.type)
      assert_equal(l, token.literal)
    end
  end
end
