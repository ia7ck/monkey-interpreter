module TokenType
  ILLEGAL = "ILLEGAL" # 未知のトークン

  IDENT = "IDENT" # 識別子 myfunc, x, y, ...
  INT = "INT" # 123, ...

  PLUS = "+"
  MINUS = "-"
  ASTERISK = "*"
  SLASH = "/"
  ASSIGN = "="
  EQUAL = "=="
  BANG = "!"
  NOT_EQUAL = "!="
  LT = "<"
  GT = ">"

  COMMA = ","
  SEMICOLON = ";"

  LPAR = "("
  RPAR = ")"
  LBRACE = "{"
  RBRACE = "}"

  FUNCTION = "FUNCTION" # fn
  LET = "LET" # let
  TRUE = "TRUE"
  FALSE = "FALSE"
  IF = "IF"
  ELSE = "ELSE"

  EOF = "$" # eof の代わり

  @keywords = {
    fn: TokenType::FUNCTION,
    let: TokenType::LET,
    true: TokenType::TRUE,
    false: TokenType::FALSE,
    if: TokenType::IF,
    else: TokenType::ELSE,
  }

  # ident が予約語なら対応する token type (FUNCTION, LET, ...) を返す
  # そうでなければ IDENT を返す
  def lookup_identifier(ident)
    @keywords.fetch(ident.intern, Token::IDENT)
  end

  module_function (:lookup_identifier)
end

class Token
  include TokenType

  attr_accessor :type, :literal

  def initialize(type, literal)
    @type = type
    @literal = literal
  end
end
