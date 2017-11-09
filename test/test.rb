require 'net/http'
require 'uri'

def raise_error
  raise('invalid response')
end

envoy_url = URI('http://localhost:9211')

Net::HTTP.start(envoy_url.host, envoy_url.port) do |http|
  response = http.get('/', Host: 'user')
  p response, response.body
  raise_error if response.code != '200'
  raise_error if response.body != 'GET,user-app,user'

  response = http.get('/', Host: 'ab-testing')
  p response, response.body
  raise_error if response.code != '200'
  raise_error if response.body != 'GET,ab-testing-app,ab-testing'

  puts 'pass'
  break
end

puts 'OK'
