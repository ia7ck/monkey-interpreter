require "./ast"
require "./object"

class MonkeyLanguageEvaluateError < StandardError; end

module Evaluator
  NULL = MonkeyNull.new
  TRUE = MonkeyBoolean.new(true)
  FALSE = MonkeyBoolean.new(false)

  Builtin = {
    "len" => MonkeyBuiltin.new(lambda { |*args|
      if args.size != 1
        raise(
          MonkeyLanguageEvaluateError,
          "wrong number of arguments: expected 1, given #{args.size}"
        )
      end
      a = args[0]
      case a
      when MonkeyString
        MonkeyInteger.new(a.value.size)
      when MonkeyArray
        MonkeyInteger.new(a.elements.size)
      else
        raise(MonkeyLanguageEvaluateError, "argument to `len` not supported, got #{a.type}")
      end
    }),
    "rest" => MonkeyBuiltin.new(lambda { |*args|
      if args.size != 1
        raise(
          MonkeyLanguageEvaluateError,
          "wrong number of arguments: expected 1, given #{args.size}"
        )
      end
      arr = args[0]
      if not arr.instance_of?(MonkeyArray)
        raise(MonkeyLanguageEvaluateError, "argument to `rest` must be ARRAY, got #{arr.type}")
      end
      elems = arr.elements[1..-1]
      if elems
        MonkeyArray.new(elems)
      else
        NULL
      end
    }),
    "push" => MonkeyBuiltin.new(lambda { |*args|
      if args.size != 2
        raise(
          MonkeyLanguageEvaluateError,
          "wrong number of arguments: expected 2, given #{args.size}"
        )
      end
      arr = args[0]
      if not arr.instance_of?(MonkeyArray)
        raise(MonkeyLanguageEvaluateError, "argument to `push` must be ARRAY, got #{arr.type}")
      end
      return MonkeyArray.new(arr.elements + [args[1]])
    }),
    "puts" => MonkeyBuiltin.new(lambda { |*args|
      puts args.map { |arg| arg.to_s }.join("\n")
      return NULL
    }),
  }

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
    when StringLiteral; MonkeyString.new(node.value)
    when IfExpression
      condition = evaluate(node.condition, env)
      eval_if_else_expression(condition, node.consequence, node.alternative, env)
    when FunctionLiteral; MonkeyFunction.new(node.parameters, node.body, env)
    when CallExpression
      function = evaluate(node.function, env)
      arguments = eval_expressions(node.arguments, env)
      apply_function(function, arguments)
    when ArrayLiteral; MonkeyArray.new(eval_expressions(node.elements, env))
    when IndexExpression
      left = evaluate(node.left, env)
      index = evaluate(node.index, env)
      eval_index_expression(left, index)
    when HashLiteral; eval_hash_literal(node, env)
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
    else raise(MonkeyLanguageEvaluateError, "unknown operator: #{operator}#{right_obj.type}")
    end
  end

  def eval_minus_prefix_operator_expression(obj)
    if obj.instance_of?(MonkeyInteger)
      MonkeyInteger.new(obj.value * (-1))
    else
      raise(MonkeyLanguageEvaluateError, "unknown operator: -#{obj.type}")
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
    when [MonkeyString, MonkeyString]
      eval_string_infix_expression(operator, left_obj, right_obj)
    else
      raise(MonkeyLanguageEvaluateError, "unknown operator: #{left_obj.type} #{operator} #{right_obj.type}")
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
      raise(MonkeyLanguageEvaluateError, "unknown operator: #{left_obj.type} #{operator} #{right_obj.type}")
    end
  end

  def eval_boolean_infix_expression(operator, left_obj, right_obj)
    case operator
    when "=="; native_bool_to_boolean_object(left_obj == right_obj)
    when "!="; native_bool_to_boolean_object(left_obj != right_obj)
    else
      raise(MonkeyLanguageEvaluateError, "unknown operator: #{left_obj.type} #{operator} #{right_obj.type}")
    end
  end

  def eval_string_infix_expression(operator, left_obj, right_obj)
    left_value, right_value = left_obj.value, right_obj.value
    case operator
    when "+"; MonkeyString.new(left_value + right_value)
    else
      raise(MonkeyLanguageEvaluateError, "unknown operator: #{left_obj.type} #{operator} #{right_obj.type}")
    end
  end

  def eval_identifier(name, env)
    value = env.get(name)
    if value
      return value
    end
    value = Builtin[name]
    if value
      return value
    end
    raise(MonkeyLanguageEvaluateError, "identifier not found: #{name}")
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

  def apply_function(func, args)
    case func
    when MonkeyFunction
      if func.parameters.size != args.size
        raise(
          MonkeyLanguageEvaluateError,
          "wrong number of arguments: expected #{func.parameters.size}, given #{args.size}"
        )
      end
      extended_env = extend_function_env(func, args)
      evaluated = evaluate(func.body, extended_env)
      return unwrap_return_value(evaluated)
    when MonkeyBuiltin
      return func.func.call(*args)
    else
      raise(MonkeyLanguageEvaluateError, "not a function: #{func.type}")
    end
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

  def eval_index_expression(left, index)
    case left
    when MonkeyArray
      eval_array_index_expression(left, index)
    when MonkeyHash
      eval_hash_index_expression(left, index)
    else
      raise(MonkeyLanguageEvaluateError, "index operator not supported #{left.type}")
    end
  end

  def eval_array_index_expression(array, index)
    if not index.instance_of?(MonkeyInteger)
      raise(MonkeyLanguageEvaluateError, "index type must be INTEGER")
    end
    elems, i = array.elements, index.value
    if i.between?(0, elems.size - 1)
      elems[i]
    else
      NULL
    end
  end

  def eval_hash_literal(node, env)
    h = MonkeyHash.new({})
    node.pairs.each do |kn, vn|
      k = evaluate(kn, env)
      if not k.kind_of?(MonkeyHashable)
        raise(MonkeyLanguageEvaluateError, "unuseable as hash key: #{k.type}")
      end
      v = evaluate(vn, env)
      h.pairs[k] = HashPair.new(k, v)
    end
    return h
  end

  def eval_hash_index_expression(h, k)
    if not k.kind_of?(MonkeyHashable)
      raise(MonkeyLanguageEvaluateError, "unuseable as hash key: #{k.type}")
    end
    v = h.pairs[k]
    if v.nil?
      return NULL
    end
    return v.value
  end
end
