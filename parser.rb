require "./token"
require "./lexer"
require "./ast"

module Precedence
  LOWEST = 1
  EQUALS = 123
  LESSGREATER = 1234
  SUM = 12345
  PRODUCT = 123456 # *, /
  PREFIX = 1234567 # -XXX, !XXX
  CALL = 123456789
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
      TokenType::MINUS,
      TokenType::BANG,
    ].zip([
      :parse_identifier_expression,
      :parse_integer_literal_expression,
      :parse_prefix_expression,
      :parse_prefix_expression,
    ].map { |name| self.method(name) }).to_h
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
      raise "got: #{@cur_token.type}, want: #{token_type}"
    end
  end

  def expect_next_token_type_is(token_type)
    if @nxt_token.type != token_type
      raise "got: #{@cur_token.type}, want: #{token_type}"
    end
    self.advance_cursor
  end

  def parse_program
    program = Program.new
    while @cur_token.type != TokenType::EOF
      stmt = self.parse_statement
      if stmt
        program.statements.push(stmt)
      end
      self.advance_cursor
    end
    return program
  end

  def parse_statement
    case @cur_token.type
    when TokenType::LET; self.parse_let_statement
    else self.parse_expression_statement
    end
  end

  def parse_let_statement
    let_stmt = LetStatement.new
    self.expect_next_token_type_is(TokenType::IDENT)
    let_stmt.name = Identifier.new(@cur_token, @cur_token.literal)
    self.expect_next_token_type_is(TokenType::ASSIGN)
    self.advance_cursor
    until self.current_token_type_is(TokenType::SEMICOLON)
      self.advance_cursor
    end
    return let_stmt
  end

  def parse_expression_statement
    stmt = ExpressionStatement.new(@cur_token)
    stmt.expression = self.parse_expression(Precedence::LOWEST)
    if self.next_token_type_is(TokenType::SEMICOLON)
      self.advance_cursor
    end
    return stmt
  end

  def parse_expression(precedence)
    prefix = @prefix_parse_functions[@cur_token.type]
    raise "not found prefix parse function for #{@cur_token.type}" if prefix.nil?
    left_expression = prefix.call
    return left_expression
  end

  def parse_identifier_expression
    Identifier.new(@cur_token, @cur_token.literal)
  end

  def parse_integer_literal_expression
    IntegerLiteral.new(@cur_token, @cur_token.literal.to_i)
  end

  def parse_prefix_expression
    expression = PrefixExpression.new(@cur_token, @cur_token.literal)
    self.advance_cursor
    expression.right_expression = self.parse_expression(Precedence::PREFIX)
    return expression
  end
end
