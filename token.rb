module Token
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

  @keywords = { fn: Token::FUNCTION, let: Token::LET }

  # ident が予約語なら対応する token type (FUNCTION, LET, ...) を返す
  # そうでなければ IDENT を返す
  def lookup_identifer(ident)
    @keywords.fetch(ident.intern, Token::IDENT)
  end

  module_function (:lookup_identifer)
end
