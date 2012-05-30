require 'rake/testtask'

task :default => [:test]


Rake::TestTask.new do |t|
  t.pattern = "./test/test_*.rb"
end

task :server do
  system("bundle exec rackup -p 8000 -s mongrel")
end
