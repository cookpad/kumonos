require 'net/http'
require 'uri'
require 'json'
require 'rack'

def raise_error(response = nil)
  p response if response
  p response.body if response
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
  puts 'waiting...'
  sleep 3
  prometheus_url = URI('http://localhost:9090')
  Net::HTTP.start(prometheus_url.host, prometheus_url.port) do |http|
    query = Rack::Utils.build_query(query: 'sum(envoy_cluster_upstream_rq_total{envoy_cluster_name!="nginx"}) by (envoy_cluster_name)')

    catch(:break) do
      i = 0
      loop do
        response = http.get("/api/v1/query?#{query}")
        p response, response.body
        raise_error(response) if response.code != '200'
        result = JSON.parse(response.body)
        if result['data']['result'].size == 2
          throw(:break)
        else
          raise_error(response) if i > 17
          puts 'waiting envoy stats to be sent...'
          sleep((2 * i) / 10.0)
          i += 1
        end
      end
    end

    query = Rack::Utils.build_query(query: 'envoy_server_live{service_cluster="test-cluster"}')

    catch(:break) do
      i = 0
      loop do
        response = http.get("/api/v1/query?#{query}")
        p response, response.body
        raise_error(response) if response.code != '200'
        result = JSON.parse(response.body)
        if result['data']['result'].size == 1
          throw(:break)
        else
          raise_error(response) if i > 17
          puts 'waiting envoy stats to be sent...'
          sleep((2 * i) / 10.0)
          i += 1
        end
      end
    end

    puts 'pass stats tag test'
  end
end

puts 'OK'
