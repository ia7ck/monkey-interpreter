module TokenType
  ILLEGAL = "ILLEGAL" # 未知のトークン

  IDENT = "IDENT" # 識別子 myfunc, x, y, ...
  INT = "INT" # 123, ...

  ASSIGN = "="
  PLUS = "+"
  MINUS = "-"
  ASTERISK = "*"

  COMMA = ","
  SEMICOLON = ";"

  LPAR = "("
  RPAR = ")"
  LBRACE = "{"
  RBRACE = "}"

  FUNCTION = "FUNCTION" # fn
  LET = "LET" # let

  EOF = "$" # eof の代わり

  @keywords = { fn: TokenType::FUNCTION, let: TokenType::LET }

  # ident が予約語なら対応する token type (FUNCTION, LET, ...) を返す
  # そうでなければ IDENT を返す
  def lookup_identifer(ident)
    @keywords.fetch(ident.intern, Token::IDENT)
  end

  module_function (:lookup_identifer)
end

class Token
  include TokenType

  attr_accessor :type, :literal

  def initialize(type, literal)
    @type = type
    @literal = literal
  end
end
