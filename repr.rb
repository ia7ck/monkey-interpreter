require "./evaluator"
require "./parser"

env = Environment.new
while true
  print "> "
  line = gets
  break if line.nil?
  pa = Parser.new(line)
  program = pa.parse_program
  begin
    evaluated = Evaluator.evaluate(program, env)
  rescue MonkeyLanguageError => err
    puts err
    next
  end
  puts evaluated # evaluated.to_s
end
