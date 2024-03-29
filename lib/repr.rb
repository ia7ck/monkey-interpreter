require_relative "evaluator"
require_relative "parser"

env = Environment.new
while true
  print "> "
  line = gets
  break if line.nil?
  pa = Parser.new(line)
  begin
    program = pa.parse_program
  rescue MonkeyLanguageParseError => err
    puts err
    next
  end
  begin
    evaluated = Evaluator.evaluate(program, env)
  rescue MonkeyLanguageEvaluateError => err
    puts err
    next
  end
  puts evaluated # evaluated.to_s
end
