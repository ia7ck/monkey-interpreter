require "./token"
require "./lexer"
require "./ast"

class Parser
  def initialize(input)
    @le = Lexer.new(input)
    @cur_token = nil
    @nxt_token = nil
    self.advance_cursor
    self.advance_cursor
  end

  def advance_cursor
    @cur_token = @nxt_token
    @nxt_token = @le.read_token
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

  def parse_let_statement
    let_stmt = LetStatement.new
    self.expect_next_token_type_is(TokenType::IDENT)
    let_stmt.name = @cur_token
    self.expect_next_token_type_is(TokenType::ASSIGN)
    self.advance_cursor
    while @cur_token.type != TokenType::SEMICOLON
      self.advance_cursor
    end
    return let_stmt
  end

  def parse_statement
    case @cur_token.type
    when TokenType::LET; self.parse_let_statement
    else nil
    end
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
end
