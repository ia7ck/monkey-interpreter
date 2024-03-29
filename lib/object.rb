module MonkeyObject
  INTEGER_OBJ = "INTEGER"
  BOOLEAN_OBJ = "BOOLEAN"
  STRING_OBJ = "STRING"
  RETURN_VALUE_OBJ = "RETURN_VALUE"
  FUNCTION_OBJ = "FUNCTION"
  ARRAY_OBJ = "ARRAY"
  HASH_OBJ = "HASH"
  STRUCT_OBJ = "STRUCT"
  INSTANCE_OBJ = "INSTANCE"
  NULL_OBJ = "NULL"
  BUILTIN_OBJ = "BUILTIN"

  def type
    raise NotImplementedError
  end

  def to_s
    raise NotImplementedError
  end
end

module MonkeyHashable
  def hash_key
    raise NotImplementedError
  end
end

class MonkeyInteger
  include MonkeyObject, MonkeyHashable
  attr_accessor :value

  def initialize(value); @value = value end
  def hash; @value.hash end
  def hash_key; hash end

  # https://docs.ruby-lang.org/ja/latest/method/Object/i/hash.html
  # a.eql?(b) ならば a.hash == b.hash

  def eql?(other)
    other.instance_of?(MonkeyInteger) and @value == other.value
  end

  def type; INTEGER_OBJ end
  def to_s; @value.to_s end
end

class MonkeyBoolean
  include MonkeyObject, MonkeyHashable
  attr_accessor :value

  def initialize(value); @value = value end
  def hash; @value.hash end
  def hash_key; hash end

  def eql?(other)
    other.instance_of?(MonkeyBoolean) and @value == other.value
  end

  def type; BOOLEAN_OBJ end
  def to_s; @value.to_s end
end

class MonkeyString
  include MonkeyObject, MonkeyHashable
  attr_accessor :value

  def initialize(value); @value = value end

  def hash; @value.hash end
  def hash_key; hash end

  def eql?(other)
    other.instance_of?(MonkeyString) and @value == other.value
  end

  def type; STRING_OBJ end
  def to_s; @value end
end

class MonkeyReturnValue
  include MonkeyObject
  attr_accessor :value

  def initialize(value); @value = value end

  def type; RETURN_VALUE_OBJ end
  def to_s; @value.to_s end
end

class MonkeyFunction
  include MonkeyObject
  attr_accessor :parameters, :body, :env

  def initialize(params, body, env)
    @parameters = params
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

  def initialize(elems); @elements = elems end
  def type; ARRAY_OBJ end
  def to_s; "[#{@elements.join(", ")}]" end
end

class HashPair
  attr_accessor :key, :value

  def initialize(key, value)
    @key = key
    @value = value
  end

  def to_s; @key.to_s + ": " + @value.to_s end
end

class MonkeyHash
  include MonkeyObject
  attr_accessor :pairs

  def initialize(pairs); @pairs = pairs end
  def type; HASH_OBJ end

  def to_s
    "{" + @pairs.values.map { |pair| pair.to_s }.join(", ") + "}"
  end
end

class MonkeyStruct
  include MonkeyObject
  attr_accessor :members

  def initialize(members); @members = members end
  def type; MonkeyStruct end
  def to_s; "struct{" + @members.join(", ") + "}" end
end

class MonkeyInstance
  include MonkeyObject
  attr_accessor :struct, :values, :map

  def initialize(struct, values)
    @struct = struct
    @values = values
    @map = @struct.members.map { |m| m.value }.zip(@values).to_h
  end

  def type; MonkeyInstance end

  def to_s
    "{" +
    @struct.members.zip(@values).map { |m, v|
      m.to_s + "=" + v.to_s
    }.join(",") +
    "}"
  end
end

class MonkeyNull
  include MonkeyObject

  def type; NULL_OBJ end
  def to_s; "null" end
end

class MonkeyBuiltin
  include MonkeyObject
  attr_accessor :func

  def initialize(func); @func = func end
  def type; BUILTIN_OBJ end
  def to_s; "builtin function" end
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
