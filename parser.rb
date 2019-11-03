require "./token"
require "./lexer"
require "./ast"

class MonkeyLanguageParseError < StandardError; end

module Precedence
  LOWEST = 1
  EQUALS = 123
  LESSGREATER = 1234
  SUM = 12345
  PRODUCT = 123456 # *, /
  PREFIX = 1234567 # -XXX, !XXX
  CALL = 123456789
  INDEX = 1234567890
end

class Parser
  def initialize(input)
    @le = Lexer.new(input)
    @cur_token = nil
    @nxt_token = nil
    self.advance_cursor
    self.advance_cursor
    # https://docs.ruby-lang.org/ja/2.2.0/class/Method.html
    @prefix_parse_functions = [
      TokenType::IDENT,
      TokenType::INT,
      TokenType::TRUE,
      TokenType::FALSE,
      TokenType::STRING,
      TokenType::IF,
      TokenType::MINUS,
      TokenType::BANG,
      TokenType::LPAR,
      TokenType::LBRACKET,
      TokenType::FUNCTION,
    ].zip([
      :parse_identifier_expression,
      :parse_integer_literal_expression,
      :parse_boolean_literal_expression,
      :parse_boolean_literal_expression,
      :parse_string_literal_expression,
      :parse_if_expression,
      :parse_prefix_expression,
      :parse_prefix_expression,
      :parse_grouped_expression,
      :parse_array_literal,
      :parse_function_literal,
    ].map { |name| self.method(name) }).to_h
    @infix_parse_functions = ([
      TokenType::EQUAL,
      TokenType::NOT_EQUAL,
      TokenType::LT,
      TokenType::GT,
      TokenType::PLUS,
      TokenType::MINUS,
      TokenType::ASTERISK,
      TokenType::SLASH,
    ].product([
      self.method(:parse_infix_expression),
    ]) + [
      [TokenType::LPAR, self.method(:parse_call_expression)],
      [TokenType::LBRACKET, self.method(:parse_index_expression)],
    ]).to_h
    @precedences = [
      TokenType::EQUAL,
      TokenType::NOT_EQUAL,
      TokenType::LT,
      TokenType::GT,
      TokenType::PLUS,
      TokenType::MINUS,
      TokenType::ASTERISK,
      TokenType::SLASH,
      TokenType::LPAR,
      TokenType::LBRACKET,
    ].zip([
      Precedence::EQUALS,
      Precedence::EQUALS,
      Precedence::LESSGREATER,
      Precedence::LESSGREATER,
      Precedence::SUM,
      Precedence::SUM,
      Precedence::PRODUCT,
      Precedence::PRODUCT,
      Precedence::CALL,
      Precedence::INDEX,
    ]).to_h
  end

  def advance_cursor
    @cur_token = @nxt_token
    @nxt_token = @le.read_token
  end

  def current_token_type_is(token_type)
    @cur_token.type == token_type
  end

  def next_token_type_is(token_type)
    @nxt_token.type == token_type
  end

  def expect_current_token_type_is(token_type)
    if @cur_token.type != token_type
      raise(MonkeyLanguageParseError, "expected token is: #{token_type}, got: #{@cur_token.type}")
    end
  end

  def expect_next_token_type_is(token_type)
    if @nxt_token.type != token_type
      raise(MonkeyLanguageParseError, "expected next token is: #{token_type}, got: #{@nxt_token.type}")
    end
    self.advance_cursor
  end

  def current_token_precedence
    @precedences[@cur_token.type] or Precedence::LOWEST
  end

  def next_token_precedence
    @precedences[@nxt_token.type] or Precedence::LOWEST
  end

  def parse_program
    program = Program.new
    while not self.current_token_type_is(TokenType::EOF)
      stmt = self.parse_statement
      raise if stmt.nil?
      program.statements.push(stmt)
      self.advance_cursor
    end
    return program
  end

  def parse_block_statement
    self.advance_cursor # {
    block_stmt = BlockStatement.new
    while (not self.current_token_type_is(TokenType::EOF)) and
          (not self.current_token_type_is(TokenType::RBRACE))
      stmt = self.parse_statement
      raise if stmt.nil?
      block_stmt.statements.push(stmt)
      self.advance_cursor
    end
    return block_stmt
  end

  def parse_statement
    case @cur_token.type
    when TokenType::LET; self.parse_let_statement
    when TokenType::RETURN; self.parse_return_statement
    else self.parse_expression_statement
    end
  end

  def parse_let_statement
    let_stmt = LetStatement.new
    self.expect_next_token_type_is(TokenType::IDENT)
    let_stmt.name = Identifier.new(@cur_token, @cur_token.literal)
    self.expect_next_token_type_is(TokenType::ASSIGN)
    self.advance_cursor
    let_stmt.value = self.parse_expression(Precedence::LOWEST)
    if self.next_token_type_is(TokenType::SEMICOLON)
      self.advance_cursor
    end
    return let_stmt
  end

  def parse_return_statement
    ret_stmt = ReturnStatement.new
    self.advance_cursor # return
    ret_stmt.return_value = self.parse_expression(Precedence::LOWEST)
    if self.next_token_type_is(TokenType::SEMICOLON)
      self.advance_cursor
    end
    return ret_stmt
  end

  def parse_expression_statement
    stmt = ExpressionStatement.new(@cur_token)
    stmt.expression = self.parse_expression(Precedence::LOWEST)
    if self.next_token_type_is(TokenType::SEMICOLON)
      self.advance_cursor
    end
    return stmt
  end

  # 1 * (2 - 3) + 4
  def parse_expression(precedence)
    prefix = @prefix_parse_functions[@cur_token.type]
    if prefix.nil?
      raise(
        MonkeyLanguageParseError,
        ["unexpected token: #{@cur_token.type}",
         "not found prefix parse function for #{@cur_token.type}"].join("\n")
      )
    end
    left_expression = prefix.call
    while (not self.next_token_type_is(TokenType::SEMICOLON)) and
          precedence < self.next_token_precedence
      infix = @infix_parse_functions[@nxt_token.type]
      if infix.nil?
        return left_expression
      end
      self.advance_cursor
      left_expression = infix.call(left_expression)
    end
    return left_expression
  end

  def parse_identifier_expression
    Identifier.new(@cur_token, @cur_token.literal)
  end

  def parse_integer_literal_expression
    IntegerLiteral.new(@cur_token, @cur_token.literal.to_i)
  end

  def parse_boolean_literal_expression
    BooleanLiteral.new(@cur_token, self.current_token_type_is(TokenType::TRUE))
  end

  def parse_string_literal_expression
    StringLiteral.new(@cur_token, @cur_token.literal)
  end

  def parse_if_expression
    ie = IfExpression.new
    self.expect_next_token_type_is(TokenType::LPAR)
    ie.condition = self.parse_expression(Precedence::LOWEST)
    self.expect_current_token_type_is(TokenType::RPAR)
    self.expect_next_token_type_is(TokenType::LBRACE)
    ie.consequence = self.parse_block_statement
    self.expect_current_token_type_is(TokenType::RBRACE)
    if self.next_token_type_is(TokenType::ELSE)
      self.advance_cursor # else
      self.expect_next_token_type_is(TokenType::LBRACE)
      ie.alternative = self.parse_block_statement
    end
    return ie
  end

  def parse_prefix_expression
    expression = PrefixExpression.new(@cur_token, @cur_token.literal)
    self.advance_cursor
    expression.right_expression = self.parse_expression(Precedence::PREFIX)
    return expression
  end

  def parse_grouped_expression # (...)
    self.advance_cursor # (
    exp = self.parse_expression(Precedence::LOWEST)
    self.expect_next_token_type_is(TokenType::RPAR)
    return exp
  end

  def parse_function_literal # fn(a, b, ...) { ... }
    fl = FunctionLiteral.new
    self.expect_next_token_type_is(TokenType::LPAR)
    fl.parameters = self.parse_function_parameters
    self.expect_current_token_type_is(TokenType::RPAR)
    self.expect_next_token_type_is(TokenType::LBRACE)
    fl.body = self.parse_block_statement
    self.expect_current_token_type_is(TokenType::RBRACE)
    return fl
  end

  def parse_function_parameters # (a, b, ...) { ... }
    identifiers = []
    self.advance_cursor # (
    while not self.current_token_type_is(TokenType::RPAR)
      if self.current_token_type_is(TokenType::IDENT)
        identifiers.push(Identifier.new(@cur_token, @cur_token.literal))
      else
        self.expect_current_token_type_is(TokenType::COMMA)
      end
      self.advance_cursor
    end
    return identifiers
  end

  def parse_infix_expression(left_expression)
    expression = InfixExpression.new(@cur_token, left_expression, @cur_token.literal)
    precedence = self.current_token_precedence
    self.advance_cursor
    expression.right_expression = self.parse_expression(precedence)
    return expression
  end

  def parse_call_expression(function)
    CallExpression.new(function, self.parse_expression_list(@cur_token.type, TokenType::RPAR))
  end

  def parse_array_literal
    ArrayLiteral.new(@cur_token, self.parse_expression_list(@cur_token.type, TokenType::RBRACKET))
  end

  def parse_expression_list(begin_token, end_token)
    exp_list = []
    self.expect_current_token_type_is(begin_token)
    self.advance_cursor # ( or [
    if self.current_token_type_is(end_token)
      self.advance_cursor
      return exp_list
    end
    exp_list.push(self.parse_expression(Precedence::LOWEST))
    while self.next_token_type_is(TokenType::COMMA)
      self.advance_cursor # exp
      self.advance_cursor # ,
      exp_list.push(self.parse_expression(Precedence::LOWEST))
    end
    self.expect_next_token_type_is(end_token)
    return exp_list
  end

  def parse_index_expression(left)
    ie = IndexExpression.new(@cur_token, left)
    self.advance_cursor # [
    ie.index = self.parse_expression(Precedence::LOWEST)
    if not self.expect_next_token_type_is(TokenType::RBRACKET)
      return nil
    end
    return ie
  end
end
