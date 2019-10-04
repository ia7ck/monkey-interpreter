require "./ast"
require "./object"

class MonkeyLanguageError < StandardError; end

module Evaluator
  NULL = MonkeyNull.new

  module_function

  def evaluate(node, env)
    case node
    when Program; eval_statements(node.statements, env)
    when ExpressionStatement; evaluate(node.expression, env)
    when LetStatement
      value = evaluate(node.value, env)
      env.set(node.name.value, value) # node.name は Identifier
    when PrefixExpression
      right_obj = evaluate(node.right_expression, env)
      eval_prefix_expression(node.operator, right_obj)
    when InfixExpression
      left_obj = evaluate(node.left_expression, env)
      right_obj = evaluate(node.right_expression, env)
      eval_infix_expression(node.operator, left_obj, right_obj)
    when Identifier; eval_identifier(node.value, env)
    when IntegerLiteral; MonkeyInteger.new(node.value)
    else nil
    end
  end

  def eval_statements(stmts, env)
    result = nil
    stmts.each do |statement|
      result = evaluate(statement, env)
    end
    return result
  end

  def eval_prefix_expression(operator, right_obj)
    case operator
    when "-"; eval_minus_prefix_operator_expression(right_obj)
    else raise(MonkeyLanguageError, "unknown operator: #{operator}#{right_obj.type}")
    end
  end

  def eval_minus_prefix_operator_expression(obj)
    if obj.instance_of?(MonkeyInteger)
      MonkeyInteger.new(obj.value * (-1))
    else
      raise(MonkeyLanguageError, "unknown operator: -#{obj.type}")
    end
  end

  def eval_infix_expression(operator, left_obj, right_obj)
    if [left_obj, right_obj].all? { |o| o.instance_of?(MonkeyInteger) }
      eval_integer_infix_expression(operator, left_obj, right_obj)
    else
      raise(MonkeyLanguageError, "unknown operator: #{left_obj.type}#{operator}#{right_obj.type}")
    end
  end

  def eval_integer_infix_expression(operator, left_obj, right_obj)
    left_value, right_value = left_obj.value, right_obj.value
    case operator
    when "+"; MonkeyInteger.new(left_value + right_value)
    when "-"; MonkeyInteger.new(left_value - right_value)
    when "*"; MonkeyInteger.new(left_value * right_value)
    when "/"; MonkeyInteger.new(left_value / right_value)
    else raise(MonkeyLanguageError, "unknown operator: #{left_obj.type}#{operator}#{right_obj.type}")
    end
  end

  def eval_identifier(name, env)
    value = env.get(name)
    raise(MonkeyLanguageError, "identifier not found: #{name}") if value.nil?
    return value
  end
end
