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
    advance_cursor
    advance_cursor
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
    ].map { |name| method(name) }).to_h
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
      method(:parse_infix_expression),
    ]) + [
      [TokenType::LPAR, method(:parse_call_expression)],
      [TokenType::LBRACKET, method(:parse_index_expression)],
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
    advance_cursor
  end

  def current_token_precedence
    @precedences[@cur_token.type] or Precedence::LOWEST
  end

  def next_token_precedence
    @precedences[@nxt_token.type] or Precedence::LOWEST
  end

  def parse_program
    program = Program.new
    while not current_token_type_is(TokenType::EOF)
      stmt = parse_statement
      raise if stmt.nil?
      program.statements.push(stmt)
      advance_cursor
    end
    return program
  end

  def parse_block_statement
    advance_cursor # {
    block_stmt = BlockStatement.new
    while (not current_token_type_is(TokenType::EOF)) and
          (not current_token_type_is(TokenType::RBRACE))
      stmt = parse_statement
      raise if stmt.nil?
      block_stmt.statements.push(stmt)
      advance_cursor
    end
    return block_stmt
  end

  def parse_statement
    case @cur_token.type
    when TokenType::LET; parse_let_statement
    when TokenType::RETURN; parse_return_statement
    else parse_expression_statement
    end
  end

  def parse_let_statement
    let_stmt = LetStatement.new
    expect_next_token_type_is(TokenType::IDENT)
    let_stmt.name = Identifier.new(@cur_token, @cur_token.literal)
    expect_next_token_type_is(TokenType::ASSIGN)
    advance_cursor
    let_stmt.value = parse_expression(Precedence::LOWEST)
    if next_token_type_is(TokenType::SEMICOLON)
      advance_cursor
    end
    return let_stmt
  end

  def parse_return_statement
    ret_stmt = ReturnStatement.new
    advance_cursor # return
    ret_stmt.return_value = parse_expression(Precedence::LOWEST)
    if next_token_type_is(TokenType::SEMICOLON)
      advance_cursor
    end
    return ret_stmt
  end

  def parse_expression_statement
    stmt = ExpressionStatement.new(@cur_token)
    stmt.expression = parse_expression(Precedence::LOWEST)
    if next_token_type_is(TokenType::SEMICOLON)
      advance_cursor
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
    while (not next_token_type_is(TokenType::SEMICOLON)) and
          precedence < next_token_precedence
      infix = @infix_parse_functions[@nxt_token.type]
      if infix.nil?
        return left_expression
      end
      advance_cursor
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
    BooleanLiteral.new(@cur_token, current_token_type_is(TokenType::TRUE))
  end

  def parse_string_literal_expression
    StringLiteral.new(@cur_token, @cur_token.literal)
  end

  def parse_if_expression
    ie = IfExpression.new
    expect_next_token_type_is(TokenType::LPAR)
    ie.condition = parse_expression(Precedence::LOWEST)
    expect_current_token_type_is(TokenType::RPAR)
    expect_next_token_type_is(TokenType::LBRACE)
    ie.consequence = parse_block_statement
    expect_current_token_type_is(TokenType::RBRACE)
    if next_token_type_is(TokenType::ELSE)
      advance_cursor # else
      expect_next_token_type_is(TokenType::LBRACE)
      ie.alternative = parse_block_statement
    end
    return ie
  end

  def parse_prefix_expression
    expression = PrefixExpression.new(@cur_token, @cur_token.literal)
    advance_cursor
    expression.right_expression = parse_expression(Precedence::PREFIX)
    return expression
  end

  def parse_grouped_expression # (...)
    advance_cursor # (
    exp = parse_expression(Precedence::LOWEST)
    expect_next_token_type_is(TokenType::RPAR)
    return exp
  end

  def parse_function_literal # fn(a, b, ...) { ... }
    fl = FunctionLiteral.new
    expect_next_token_type_is(TokenType::LPAR)
    fl.parameters = parse_function_parameters
    expect_current_token_type_is(TokenType::RPAR)
    expect_next_token_type_is(TokenType::LBRACE)
    fl.body = parse_block_statement
    expect_current_token_type_is(TokenType::RBRACE)
    return fl
  end

  def parse_function_parameters # (a, b, ...) { ... }
    identifiers = []
    advance_cursor # (
    while not current_token_type_is(TokenType::RPAR)
      if current_token_type_is(TokenType::IDENT)
        identifiers.push(Identifier.new(@cur_token, @cur_token.literal))
      else
        expect_current_token_type_is(TokenType::COMMA)
      end
      advance_cursor
    end
    return identifiers
  end

  def parse_infix_expression(left_expression)
    expression = InfixExpression.new(@cur_token, left_expression, @cur_token.literal)
    precedence = current_token_precedence
    advance_cursor
    expression.right_expression = parse_expression(precedence)
    return expression
  end

  def parse_call_expression(function)
    CallExpression.new(function, parse_expression_list(@cur_token.type, TokenType::RPAR))
  end

  def parse_array_literal
    ArrayLiteral.new(@cur_token, parse_expression_list(@cur_token.type, TokenType::RBRACKET))
  end

  def parse_expression_list(begin_token, end_token)
    exp_list = []
    expect_current_token_type_is(begin_token)
    advance_cursor # ( or [
    if current_token_type_is(end_token)
      return exp_list
    end
    exp_list.push(parse_expression(Precedence::LOWEST))
    while next_token_type_is(TokenType::COMMA)
      advance_cursor # exp
      advance_cursor # ,
      exp_list.push(parse_expression(Precedence::LOWEST))
    end
    expect_next_token_type_is(end_token)
    return exp_list
  end

  def parse_index_expression(left)
    ie = IndexExpression.new(@cur_token, left)
    advance_cursor # [
    ie.index = parse_expression(Precedence::LOWEST)
    if not expect_next_token_type_is(TokenType::RBRACKET)
      return nil
    end
    return ie
  end
end
