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
end
