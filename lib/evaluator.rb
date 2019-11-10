require_relative "ast"
require_relative "object"

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
      when MonkeyString; MonkeyInteger.new(a.value.size)
      when MonkeyArray; MonkeyInteger.new(a.elements.size)
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
      right_obj = evaluate(node.right, env)
      eval_prefix_expression(node.operator, right_obj)
    when InfixExpression
      left_obj = evaluate(node.left, env)
      right_obj = evaluate(node.right, env)
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
    when StructLiteral; eval_struct_literal(node, env)
    when InitializeExpression
      struct = evaluate(node.struct, env)
      values = eval_expressions(node.values, env)
      eval_initialize_expression(struct, values)
    when MemberAccessExpression
      instance = evaluate(node.instance, env)
      member = node.member.value # !?
      eval_member_access_expression(instance, member)
    else nil
    end
  end

  def native_bool_to_boolean_object(b); b ? TRUE : FALSE end

  def eval_program(program, env)
    res = nil
    program.statements.each do |statement|
      res = evaluate(statement, env)
      if res.instance_of?(MonkeyReturnValue)
        return res.value
      end
    end
    return res
  end

  def eval_block_statement(block, env)
    res = nil
    block.statements.each do |statement|
      res = evaluate(statement, env)
      if res and res.type == MonkeyObject::RETURN_VALUE_OBJ
        return res
      end
    end
    return res
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

  def eval_infix_expression(op, left, right)
    case [left, right].map { |o| o.class }
    when [MonkeyInteger, MonkeyInteger]
      eval_integer_infix_expression(op, left, right)
    when [MonkeyBoolean, MonkeyBoolean]
      eval_boolean_infix_expression(op, left, right)
    when [MonkeyString, MonkeyString]
      eval_string_infix_expression(op, left, right)
    else
      raise(MonkeyLanguageEvaluateError, "unknown operator: #{left.type} #{op} #{right.type}")
    end
  end

  def eval_integer_infix_expression(op, left, right)
    l_val, r_val = left.value, right.value
    case op
    when "+"; MonkeyInteger.new(l_val + r_val)
    when "-"; MonkeyInteger.new(l_val - r_val)
    when "*"; MonkeyInteger.new(l_val * r_val)
    when "/"; MonkeyInteger.new(l_val / r_val)
    when "=="; native_bool_to_boolean_object(l_val == r_val)
    when "!="; native_bool_to_boolean_object(l_val != r_val)
    when "<"; native_bool_to_boolean_object(l_val < r_val)
    when ">"; native_bool_to_boolean_object(l_val > r_val)
    else
      raise(MonkeyLanguageEvaluateError, "unknown operator: #{left.type} #{op} #{right.type}")
    end
  end

  def eval_boolean_infix_expression(op, left, right)
    case op
    when "=="; native_bool_to_boolean_object(left == right)
    when "!="; native_bool_to_boolean_object(left != right)
    else
      raise(MonkeyLanguageEvaluateError, "unknown operator: #{left.type} #{op} #{right.type}")
    end
  end

  def eval_string_infix_expression(op, left, right)
    l_val, r_val = left.value, right.value
    case op
    when "+"; MonkeyString.new(l_val + r_val)
    else
      raise(MonkeyLanguageEvaluateError, "unknown operator: #{left.type} #{op} #{right.type}")
    end
  end

  def eval_identifier(name, env)
    val = env.get(name)
    return val if val
    val = Builtin[name]
    return val if val
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

  def eval_expressions(exps, env)
    exps.map { |exp| evaluate(exp, env) }
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

  def extend_function_env(func, args)
    env = Environment.new(outer: func.env)
    func.parameters.zip(args).each do |param, arg|
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

  def eval_struct_literal(node, env)
    exps = eval_expressions(node.members, env)
    if not exps.all? { |exp| exp.instance_of?(MonkeyString) }
      raise(MonkeyLanguageEvaluateError, "struct member type must be STRING")
    end
    if not exps.all? { |exp| exp.value =~ /^[a-zA-Z]\w*/ }
      raise(MonkeyLanguageEvaluateError, "struct member name must begin [a-zA-Z]")
    end
    return MonkeyStruct.new(exps)
  end

  def eval_initialize_expression(struct, vals)
    if not struct.instance_of?(MonkeyStruct)
      raise(MonkeyLanguageEvaluateError, "initialize operator not supported #{struct.type}")
    end
    if struct.members.size < vals.size
      raise(
        MonkeyLanguageEvaluateError,
        "wrong number of arguments: expected #{struct.members.size}, given #{vals.size}"
      )
    end
    while vals.size < struct.members.size
      vals.push(NULL)
    end
    return MonkeyInstance.new(struct, vals)
  end

  def eval_member_access_expression(instance, member)
    if not instance.map.include?(member)
      raise(MonkeyLanguageEvaluateError, "not found #{member} in #{instance.struct}")
    end
    return instance.map[member]
  end
end
