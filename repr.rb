require "./evaluator"
require "./parser"

while true
  print "> "
  line = gets
  break if line.nil?
  pa = Parser.new(line)
  begin
    program = pa.parse_program
  rescue => err
    puts err
    next
  end
  evaluated = evaluate(program)
  if evaluated
    puts evaluated.inspect
  end
end
