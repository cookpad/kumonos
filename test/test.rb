require 'net/http'
require 'uri'

def raise_error(response)
  raise('invalid response')
end

envoy_url = URI('http://localhost:9211')

Net::HTTP.start(envoy_url.host, envoy_url.port) do |http|
  response = http.get('/', Host: 'user')
  p response
  raise_error(response) if response.code != '200'
  raise_error(response) if response.body != 'GET and user'

  response = http.get('/', Host: 'ab-testing')
  p response
  raise_error(response) if response.code != '200'
  raise_error(response) if response.body != 'GET and ab-testing'

  puts 'pass'
  break
end

puts 'OK'
