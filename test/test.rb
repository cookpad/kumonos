require 'net/http'
require 'uri'
require 'json'
require 'rack'

def raise_error
  raise('invalid response')
end

envoy_url = URI('http://localhost:9211')

catch(:break) do
  i = 0
  loop do
    begin
      Net::HTTP.start(envoy_url.host, envoy_url.port) do |http|
        response = http.get('/')
        throw(:break) if response.code == '404'
      end
    rescue EOFError, SystemCallError
      raise('Can not run the envoy container') if i == 19 # Overall retries end within 3.8s.
      puts 'waiting the envoy container to run...'
      sleep((2 * i) / 100.0)
      i += 1
    end
  end
end

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
end

if ENV['TEST_WITH_RELAY'] == '1'
  puts 'waiting 30s till metrics to be sent...'
  sleep 30
  prometheus_url = URI('http://localhost:9090')
  Net::HTTP.start(prometheus_url.host, prometheus_url.port) do |http|
    query = Rack::Utils.build_query(query: 'sum(envoy_cluster_upstream_rq_200_counter{cluster!="discovery_service"}) by (cluster)')
    response = http.get("/api/v1/query?#{query}")
    p response, response.body
    raise_error if response.code != '200'
    result = JSON.parse(response.body)
    p result
    raise_error unless result['data']['result'].size == 2

    puts 'pass relay test'
  end
end

puts 'OK'
