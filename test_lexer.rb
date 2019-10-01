require "minitest/autorun"

require "./token"
require "./lexer"

class TestLexer < Minitest::Test
  def test_read_token
    input = <<~EOS
      let v = 2 * (3 + 4);
      a + -23;
    EOS
    le = Lexer.new(input)
    tests = [
      [Token::LET, "let"],
      [Token::IDENT, "v"],
      [Token::ASSIGN, "="],
      [Token::INT, "2"],
      [Token::ASTERISK, "*"],
      [Token::LPAR, "("],
      [Token::INT, "3"],
      [Token::PLUS, "+"],
      [Token::INT, "4"],
      [Token::RPAR, ")"],
      [Token::SEMICOLON, ";"],
      [Token::IDENT, "a"],
      [Token::PLUS, "+"],
      [Token::MINUS, "-"],
      [Token::INT, "23"],
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
