module MonkeyObject
  INT_OBJ = "INTEGER"
  NULL_OBJ = "NULL"

  def type
    raise NotImplementedError
  end

  def inspect
    raise NotImplementedError
  end
end

class MonkeyInteger
  include MonkeyObject

  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def type
    INT_OBJ
  end

  def inspect
    @value.to_s
  end
end

class MonkeyNull
  include MonkeyObject

  def type
    NULL_OBJ
  end

  def inspect
    "null"
  end
end
