require "./token"

class Lexer
  def initialize(input)
    @input = input.strip
    @pos = -1 # @input[@pos] == @char
    @nxt_pos = 0 # 次に読む文字の位置
    @char = ""
    self.read_char
  end

  def read_char
    @char = @nxt_pos >= @input.size ? "$" : @input[@nxt_pos]
    @pos = @nxt_pos
    @nxt_pos += 1
    return @char
  end

  def next_token
    self.skip_whitespace
    t = []
    case @char
    when "+"; t = [Token::PLUS, "+"]
    when "="; t = [Token::ASSIGN, "="]
    when ","; t = [Token::COMMA, ","]
    when ";"; t = [Token::SEMICOLON, ";"]
    when "("; t = [Token::LPAR, "("]
    when ")"; t = [Token::RPAR, ")"]
    when "{"; t = [Token::LBRACE, "{"]
    when "}"; t = [Token::RBRACE, "}"]
    when /^[a-zA-Z_]$/
      ident = self.read_identifer
      return [Token::lookup_identifer(ident), ident]
    else t = [Token::ILLEGAL, "ILLEGAL"]
    end
    self.read_char
    return t
  end

  def skip_whitespace
    while @char =~ /^\s$/
      self.read_char
    end
  end

  def read_identifer
    left = @pos
    while @char =~ /^\w$/
      self.read_char
    end
    return @input[left...@pos] # [left, @pos)
  end
end
