require "./token"

module Node
  def token_literal
    raise NotImplementedError
  end

  def to_str
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

  def to_str; @statements.join(" ") end
end

class BlockStatement < Statement
  attr_accessor :statements

  def initialize
    @token = Token.new(TokenType::LBRACE, "{")
    @statements = []
  end

  def token_literal; @token.literal end
  def to_str; @statements.join(" ") end
end

class LetStatement < Statement
  attr_accessor :name, :value

  def initialize
    @token = Token.new(TokenType::LET, "let")
    @name = nil
    @value = nil
  end

  def token_literal; @token.literal end

  # to_s で実装すると変数展開のときにいい感じにしてくれるらしい
  # to_str だと "let = " + @name + " = " + @value とかすればいい
  def to_str; "let #{@name.to_str} = #{@value.to_str}" end
end

class ExpressionStatement < Statement
  attr_accessor :token, :expression

  def initialize(token)
    @token = token # 式の最初に現れる token
    @expression = nil
  end

  def token_literal; @token.literal end
  def to_str; @expression.to_str end
end

class Identifier < Expression
  attr_accessor :token, :value

  def initialize(token, value)
    @token = token
    @value = value
  end

  def token_literal; @token.literal end
  def to_str; @token.literal end
end

class IntegerLiteral < Expression
  attr_accessor :token, :value

  def initialize(token, value)
    @token = token
    @value = value
  end

  def token_literal; @token.literal end
  def to_str; @token.literal end
end

class FunctionLiteral < Expression
  attr_accessor :parameters, :body

  def initialize
    @token = Token.new(TokenType::FUNCTION, "fn")
    @parameters = []
    @body = nil
  end

  def token_literal; @token.literal end

  def to_str
    "#{@token.literal} (#{@parameters.join(", ")}) #{@body.to_str}"
  end
end

class PrefixExpression < Expression
  attr_accessor :operator, :right_expression

  def initialize(token, operator)
    @token = token
    @operator = operator
    @right_expression = nil
  end

  def token_literal; @token.literal end
  def to_str; "(#{@operator}#{@right_expression.to_str})" end
end

class InfixExpression < Expression
  attr_accessor :left_expression, :operator, :right_expression

  def initialize(token, left_expression, operator)
    @token = token
    @left_expression = left_expression
    @operator = operator
    @right_expression = nil
  end

  def to_str
    "(#{@left_expression.to_str} #{@operator} #{@right_expression.to_str})"
  end
end

class CallExpression < Expression
  attr_accessor :function, :arguments

  def initialize(function, arguments)
    @token = Token.new(TokenType::LPAR, "(")
    @function = function # identifier or function_literal
    @arguments = arguments
  end

  def token_literal; @token.literal end
  def to_str; "#{@function.to_str}(#{@arguments.join(", ")})" end
end
