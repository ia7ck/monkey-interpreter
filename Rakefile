require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList["test/test_*.rb"]
end

task :fibonacci do
  ruby "example/fibonacci.rb"
end
