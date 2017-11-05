require 'sinatra'

get '/' do
  sleep ENV['SLEEP'].to_f
  raise 'error' if rand(0..ENV['ERROR_RATE'].to_i) == 0
  "GET and #{ENV['RESPONSE'] || 'hello'}"
end

post '/' do
  raise 'error' if rand(0..ENV['ERROR_RATE'].to_i) == 0
  "POST and #{ENV['RESPONSE'] || 'hello'}"
end
