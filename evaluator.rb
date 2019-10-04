require "./ast"
require "./object"

module Evaluator
  NULL = MonkeyNull.new

  module_function

  def evaluate(node)
    case node
    when Program; eval_statements(node.statements)
    when ExpressionStatement; evaluate(node.expression)
    when PrefixExpression
      right_obj = evaluate(node.right_expression)
      eval_prefix_expression(node.operator, right_obj)
    when InfixExpression
      left_obj = evaluate(node.left_expression)
      right_obj = evaluate(node.right_expression)
      eval_infix_expression(node.operator, left_obj, right_obj)
    when IntegerLiteral; MonkeyInteger.new(node.value)
    else nil
    end
  end

  def eval_statements(stmts)
    result = nil
    stmts.each do |statement|
      result = evaluate(statement)
    end
    return result
  end

  def eval_prefix_expression(operator, right_obj)
    case operator
    when "-"; eval_minus_prefix_operator_expression(right_obj)
    else NULL
    end
  end

  def eval_minus_prefix_operator_expression(obj)
    if obj.instance_of?(MonkeyInteger)
      MonkeyInteger.new(obj.value * (-1))
    else
      NULL
    end
  end

  def eval_infix_expression(operator, left_obj, right_obj)
    if [left_obj, right_obj].all? { |o| o.instance_of?(MonkeyInteger) }
      eval_integer_infix_expression(operator, left_obj, right_obj)
    else
      NULL
    end
  end

  def eval_integer_infix_expression(operator, left_obj, right_obj)
    left_value, right_value = left_obj.value, right_obj.value
    case operator
    when "+"; MonkeyInteger.new(left_value + right_value)
    when "-"; MonkeyInteger.new(left_value - right_value)
    when "*"; MonkeyInteger.new(left_value * right_value)
    when "/"; MonkeyInteger.new(left_value / right_value)
    else NULL
    end
  end
end
