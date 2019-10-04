require "./ast"
require "./object"

module Evaluator
  module_function

  def evaluate(node)
    case node
    when Program; eval_statements(node.statements)
    when ExpressionStatement; evaluate(node.expression)
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
end
