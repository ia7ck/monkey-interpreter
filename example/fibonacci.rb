require_relative "../lib/parser"
require_relative "../lib/evaluator"

input = <<EOS
    let fib = fn(n) {
        if (n == 0) { return 0; }
        if (n == 1) { return 1; }
        return fib(n - 1) + fib(n - 2);
    };
    fib(30);
EOS
parser = Parser.new(input)
program = parser.parse_program

start = Time.now
env = Environment.new
result = Evaluator.evaluate(program, env)
stop = Time.now

puts "Program"
puts input
puts "took #{stop - start} seconds"
puts "result: #{result}"
