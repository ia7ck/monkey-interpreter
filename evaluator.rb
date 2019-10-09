require "./ast"
require "./object"

class MonkeyLanguageError < StandardError; end

module Evaluator
  NULL = MonkeyNull.new
  TRUE = MonkeyBoolean.new(true)
  FALSE = MonkeyBoolean.new(false)

  module_function

  def evaluate(node, env)
    case node
    when Program; eval_program(node, env)
    when ExpressionStatement; evaluate(node.expression, env)
    when LetStatement
      value = evaluate(node.value, env)
      env.set(node.name.value, value) # node.name は Identifier
    when ReturnStatement
      value = evaluate(node.return_value, env)
      MonkeyReturnValue.new(value)
    when BlockStatement; eval_block_statement(node, env)
    when PrefixExpression
      right_obj = evaluate(node.right_expression, env)
      eval_prefix_expression(node.operator, right_obj)
    when InfixExpression
      left_obj = evaluate(node.left_expression, env)
      right_obj = evaluate(node.right_expression, env)
      eval_infix_expression(node.operator, left_obj, right_obj)
    when Identifier; eval_identifier(node.value, env)
    when IntegerLiteral; MonkeyInteger.new(node.value)
    when BooleanLiteral; native_bool_to_boolean_object(node.value)
    when IfExpression
      condition = evaluate(node.condition, env)
      eval_if_else_expression(condition, node.consequence, node.alternative, env)
    when FunctionLiteral; MonkeyFunction.new(node.parameters, node.body, env)
    when CallExpression
      function = evaluate(node.function, env)
      arguments = eval_expressions(node.arguments, env)
      apply_function(function, arguments)
    else nil
    end
  end

  def native_bool_to_boolean_object(b); b ? TRUE : FALSE end

  def eval_program(program, env)
    result = nil
    program.statements.each do |statement|
      result = evaluate(statement, env)
      if result.instance_of?(MonkeyReturnValue)
        return result.value
      end
    end
    return result
  end

  def eval_block_statement(block, env)
    result = nil
    block.statements.each do |statement|
      result = evaluate(statement, env)
      if result and result.type == MonkeyObject::RETURN_VALUE_OBJ
        return result
      end
    end
    return result
  end

  def eval_prefix_expression(operator, right_obj)
    case operator
    when "-"; eval_minus_prefix_operator_expression(right_obj)
    when "!"; eval_bang_operator_expression(right_obj)
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

  def eval_bang_operator_expression(obj)
    (obj == NULL or obj == FALSE) ? TRUE : FALSE
  end

  def eval_infix_expression(operator, left_obj, right_obj)
    case [left_obj, right_obj].map { |o| o.class }
    when [MonkeyInteger, MonkeyInteger]
      eval_integer_infix_expression(operator, left_obj, right_obj)
    when [MonkeyBoolean, MonkeyBoolean]
      eval_boolean_infix_expression(operator, left_obj, right_obj)
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
    when "=="; native_bool_to_boolean_object(left_value == right_value)
    when "!="; native_bool_to_boolean_object(left_value != right_value)
    when "<"; native_bool_to_boolean_object(left_value < right_value)
    when ">"; native_bool_to_boolean_object(left_value > right_value)
    else
      raise(MonkeyLanguageError, "unknown operator: #{left_obj.type}#{operator}#{right_obj.type}")
    end
  end

  def eval_boolean_infix_expression(operator, left_obj, right_obj)
    case operator
    when "=="; native_bool_to_boolean_object(left_obj == right_obj)
    when "!="; native_bool_to_boolean_object(left_obj != right_obj)
    else
      raise(MonkeyLanguageError, "unknown operator: #{left_obj.type}#{operator}#{right_obj.type}")
    end
  end

  def eval_identifier(name, env)
    value = env.get(name)
    raise(MonkeyLanguageError, "identifier not found: #{name}") if value.nil?
    return value
  end

  def eval_if_else_expression(condition, consequence, alternative, env)
    if is_truthy(condition)
      evaluate(consequence, env)
    elsif alternative
      evaluate(alternative, env)
    else
      NULL
    end
  end

  def is_truthy(obj)
    obj != NULL and obj != FALSE
  end

  def eval_expressions(arguments, env)
    arguments.map { |arg| evaluate(arg, env) }
  end

  def apply_function(function, arguments)
    if function.parameters.size != arguments.size
      raise(
        MonkeyLanguageError,
        "wrong number of arguments: expected #{function.parameters.size}, given #{arguments.size}"
      )
    end
    extended_env = extend_function_env(function, arguments)
    evaluated = evaluate(function.body, extended_env)
    unwrap_return_value(evaluated)
  end

  def extend_function_env(function, arguments)
    env = Environment.new(outer: function.env)
    function.parameters.zip(arguments).each do |param, arg|
      env.set(param.value, arg)
    end
    return env
  end

  # fn() { fn() { return ooo } }
  def unwrap_return_value(obj)
    obj.instance_of?(MonkeyReturnValue) ? obj.value : obj
  end
end
