require 'sinatra'

get '/' do
  sleep ENV['SLEEP'].to_f
  raise 'error' if rand(0..ENV['ERROR_RATE'].to_i).zero?
  "GET and #{ENV['RESPONSE'] || 'hello'}"
end

post '/' do
  raise 'error' if rand(0..ENV['ERROR_RATE'].to_i).zero?
  "POST and #{ENV['RESPONSE'] || 'hello'}"
end
