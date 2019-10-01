require "./token"

module Node
  def token_literal
    raise NotImplementedError
  end
end

class Statement
  include Node
end

class Expression
  include Node
end

class Program
  attr_accessor :statements

  def initialize
    @statements = []
  end
end

class LetStatement < Statement
  attr_accessor :name, :value

  def initialize
    @token = Token.new(TokenType::LET, "let")
    @name = nil
    @value = nil
  end

  def token_literal
    @token.literal
  end
end

class ExpressionStatement < Statement
  attr_accessor :token, :expression

  def initialize(token)
    @token = token # 式の最初に現れる token
    @expression = nil
  end

  def token_literal
    @token.literal
  end
end

class Identifier < Expression
  attr_accessor :token, :value

  def initialize(token, value)
    @token = token
    @value = value
  end
end

class IntegerLiteral < Expression
  attr_accessor :token, :value

  def initialize(token, value)
    @token = token
    @value = value
  end
end
