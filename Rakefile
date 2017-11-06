require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc 'Run integration test'
task :integration_test do
  Dir.chdir('test') do
    sh './run_test'
  end
end

desc 'Run all tests'
task all: %i[spec rubocop integration_test]
