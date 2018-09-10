# frozen_string_literal: true

require 'resolv'
require 'sinatra'

get '/' do
  sleep ENV['SLEEP'].to_f
  raise 'error' if ENV['ERROR_RATE'] && rand(0..ENV['ERROR_RATE'].to_i).zero?

  "GET,#{env['HTTP_HOST']},#{ENV['RESPONSE']}"
end

post '/' do
  raise 'error' if rand(0..ENV['ERROR_RATE'].to_i).zero?

  "POST and #{ENV['RESPONSE'] || 'hello'}"
end

get '/ip/:name' do
  Resolv.getaddress(params[:name])
end
