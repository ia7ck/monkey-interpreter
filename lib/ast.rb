require_relative "token"

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

  def token_literal; @token.literal end
end

class Expression
  include Node

  def token_literal; @token.literal end
end

class Program
  attr_accessor :statements

  def initialize; @statements = [] end
  def to_str; @statements.join(" ") end
end

class BlockStatement < Statement
  attr_accessor :statements

  def initialize(token, stmts)
    @token = token
    @statements = stmts
  end

  def to_str; @statements.join(" ") end
end

class LetStatement < Statement
  attr_accessor :name, :value

  def initialize(token)
    @token = token
    @name = nil
    @value = nil
  end

  def to_str; "let " + @name + " = " + @value end
end

class ReturnStatement < Statement
  attr_accessor :return_value

  def initialize(token)
    @token = token
    @return_value = nil
  end

  def to_str; "return " + @return_value end
end

class ExpressionStatement < Statement
  attr_accessor :token, :expression

  def initialize(token)
    @token = token # 式の最初に現れる token
    @expression = nil
  end

  def to_str; @expression.to_str end
end

class Identifier < Expression
  attr_accessor :value

  def initialize(token, value)
    @token = token
    @value = value
  end

  def to_str; @token.literal end
end

class IntegerLiteral < Expression
  attr_accessor :value

  def initialize(token, value)
    @token = token
    @value = value
  end

  def to_str; @token.literal end
end

class BooleanLiteral < Expression
  attr_accessor :value

  def initialize(token, value)
    @token = token
    @value = value
  end

  def to_str; @token.literal end
end

class StringLiteral < Expression
  attr_accessor :value

  def initialize(token, value)
    @token = token
    @value = value
  end

  def to_str; @token.literal end
end

class IfExpression < Expression
  attr_accessor :condition, :consequence, :alternative

  def initialize(token)
    @token = token
    @condition = nil
    @consequence = nil
    @alternative = nil
  end

  def to_str
    if @alternative
      "if (" + @condition + ")" + @consequence + "else" + @alternative
    else
      "if (" + @condition + ")" + @consequence
    end
  end
end

class PrefixExpression < Expression
  attr_accessor :operator, :right

  def initialize(token, operator)
    @token = token
    @operator = operator
    @right = nil
  end

  def to_str; "(" + @operator + @right + ")" end
end

class FunctionLiteral < Expression
  attr_accessor :parameters, :body

  def initialize(token)
    @token = token
    @parameters = []
    @body = nil
  end

  def to_str
    @token.literal + "(" + @parameters.join(", ") + ")" + @body
  end
end

class InfixExpression < Expression
  attr_accessor :left, :operator, :right

  def initialize(token, left, op)
    @token = token
    @left = left
    @operator = op
    @right = nil
  end

  def to_str
    "(" + @left + " " + @operator + " " + @right + ")"
  end
end

class CallExpression < Expression
  attr_accessor :function, :arguments

  def initialize(func, args)
    @token = Token.new(TokenType::LPAR, "(")
    @function = func # identifier or function_literal
    @arguments = args
  end

  def to_str; @function.to_str + "(" + @arguments.join(", ") + ")" end
end

class ArrayLiteral < Expression
  attr_accessor :elements

  def initialize(token, elems)
    @token = token
    @elements = elems
  end

  def to_str; "[#{@elements.join(", ")}]" end
end

class IndexExpression < Expression
  attr_accessor :left, :index

  def initialize(token, left)
    @token = token # [
    @left = left
    @index = nil
  end

  def to_str; "(" + @left + "[" + @index + "])" end
end

class HashLiteral < Expression
  attr_accessor :pairs

  def initialize(token, pairs)
    @token = token
    @pairs = pairs
  end

  def to_str
    "{" +
      @pairs.map { |k, v|
        k.to_str + ": " + v.to_str
      }.join(", ") +
    "}"
  end
end

class StructLiteral < Expression
  attr_accessor :members

  def initialize(token, members)
    @token = token
    @members = members
  end

  def to_str; "struct{" + @members.join(", ") + "}" end
end

class InitializeExpression < Expression
  attr_accessor :struct, :values

  def initialize(token, struct, values)
    @token = token # {
    @struct = struct # identifier or struct_literal
    @values = values
  end

  def to_str; @struct + "{" + @values.join(", ") + "}" end
end

class MemberAccessExpression < Expression
  attr_accessor :instance, :operator, :member

  def initialize(token, instance, op)
    @token = token
    @instance = instance
    @operator = op  # .
    @member = nil
  end

  def to_str; "(" + @instance + @operator + @member + ")" end
end
