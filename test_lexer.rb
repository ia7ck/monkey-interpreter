require "minitest/autorun"

require "./token"
require "./lexer"

class TestLexer < Minitest::Test
  def test_read_token
    input = <<~EOS
      let v = 2 * (3 + 4);
      a + -23;
      1 != 2;
      2 < 3;
      if (true == false) {1} else { return 0 }
      "a bc"
    EOS
    le = Lexer.new(input)
    tests = [
      [TokenType::LET, "let"],
      [TokenType::IDENT, "v"],
      [TokenType::ASSIGN, "="],
      [TokenType::INT, "2"],
      [TokenType::ASTERISK, "*"],
      [TokenType::LPAR, "("],
      [TokenType::INT, "3"],
      [TokenType::PLUS, "+"],
      [TokenType::INT, "4"],
      [TokenType::RPAR, ")"],
      [TokenType::SEMICOLON, ";"],
      [TokenType::IDENT, "a"],
      [TokenType::PLUS, "+"],
      [TokenType::MINUS, "-"],
      [TokenType::INT, "23"],
      [TokenType::SEMICOLON, ";"],
      [TokenType::INT, "1"],
      [TokenType::NOT_EQUAL, "!="],
      [TokenType::INT, "2"],
      [TokenType::SEMICOLON, ";"],
      [TokenType::INT, "2"],
      [TokenType::LT, "<"],
      [TokenType::INT, "3"],
      [TokenType::SEMICOLON, ";"],
      [TokenType::IF, "if"],
      [TokenType::LPAR, "("],
      [TokenType::TRUE, "true"],
      [TokenType::EQUAL, "=="],
      [TokenType::FALSE, "false"],
      [TokenType::RPAR, ")"],
      [TokenType::LBRACE, "{"],
      [TokenType::INT, "1"],
      [TokenType::RBRACE, "}"],
      [TokenType::ELSE, "else"],
      [TokenType::LBRACE, "{"],
      [TokenType::RETURN, "return"],
      [TokenType::INT, "0"],
      [TokenType::RBRACE, "}"],
      [TokenType::STRING, "a bc"],
      [TokenType::EOF, "$"],
    ]
    tests.each do |t, l|
      token = le.read_token
      assert_equal(t, token.type)
      assert_equal(l, token.literal)
    end
  end
end
