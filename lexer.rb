require "./token"

class String
  def alpha?
    raise if self.size != 1
    o = self.ord
    return (("a".ord <= o and o <= "z".ord) or ("A".ord <= o and o <= "Z".ord))
  end

  def digit?
    raise if self.size != 1
    o = self.ord
    return ("0".ord <= o and o <= "9".ord)
  end

  def letter?
    raise if self.size != 1
    return (self.alpha? or self.digit? or self == "_")
  end

  def whitespace?
    raise if self.size != 1
    return [" ", "\t", "\n", "\r"].include?(self)
  end
end

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

  def read_token
    self.skip_whitespace
    t = nil
    case @char
    when "+"; t = Token.new(TokenType::PLUS, "+")
    when "="; t = Token.new(TokenType::ASSIGN, "=")
    when ","; t = Token.new(TokenType::COMMA, ",")
    when ";"; t = Token.new(TokenType::SEMICOLON, ";")
    when "("; t = Token.new(TokenType::LPAR, "(")
    when ")"; t = Token.new(TokenType::RPAR, ")")
    when "{"; t = Token.new(TokenType::LBRACE, "{")
    when "}"; t = Token.new(TokenType::RBRACE, "}")
    when lambda { |c| c.alpha? }
      ident = self.read_identifer
      return Token.new(TokenType::lookup_identifer(ident), ident)
    when "$"; t = Token.new(TokenType::EOF, "$")
    else t = Token.new(TokenType::ILLEGAL, "ILLEGAL")
    end
    self.read_char
    return t
  end

  def skip_whitespace
    while @char.whitespace?
      self.read_char
    end
  end

  def read_identifer
    left = @pos
    while @char.letter?
      self.read_char
    end
    return @input[left...@pos] # [left, @pos)
  end
end
