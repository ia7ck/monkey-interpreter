module MonkeyObject
  INTEGER_OBJ = "INTEGER"
  BOOLEAN_OBJ = "BOOLEAN"
  STRING_OBJ = "STRING"
  RETURN_VALUE_OBJ = "RETURN_VALUE"
  FUNCTION_OBJ = "FUNCTION"
  ARRAY_OBJ = "ARRAY"
  NULL_OBJ = "NULL"

  def type
    raise NotImplementedError
  end

  def to_s
    raise NotImplementedError
  end
end

class MonkeyInteger
  include MonkeyObject
  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def type; INTEGER_OBJ end
  def to_s; @value.to_s end
end

class MonkeyBoolean
  include MonkeyObject
  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def type; BOOLEAN_OBJ end
  def to_s; @value.to_s end
end

class MonkeyString
  include MonkeyObject
  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def type; STRING_OBJ end
  def to_s; @value end
end

class MonkeyReturnValue
  include MonkeyObject
  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def type; RETURN_VALUE_OBJ end
  def to_s; @value.to_s end
end

class MonkeyFunction
  include MonkeyObject
  attr_accessor :parameters, :body, :env

  def initialize(parameters, body, env)
    @parameters = parameters
    @body = body
    @env = env
  end

  def type; FUNCTION_OBJ end

  def to_s
    <<~EOS
      fn(#{parameters.join(", ")}) {
        #{@body.to_str}
      }
    EOS
  end
end

class MonkeyArray
  include MonkeyObject
  attr_accessor :elements

  def initialize(elems)
    @elements = elems
  end

  def type; ARRAY_OBJ end
  def to_s; "[#{@elements.join(", ")}]" end
end

class MonkeyNull
  include MonkeyObject

  def type; NULL_OBJ end
  def to_s; "null" end
end

# environment
class Environment
  def initialize(outer: nil)
    @outer = outer
    @store = {}
  end

  def get(name)
    obj = @store[name.intern]
    if obj.nil? and @outer
      obj = @outer.get(name)
    end
    return obj
  end

  def set(name, obj)
    @store[name.intern] = obj
  end
end
