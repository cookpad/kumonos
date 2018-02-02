require 'cgi'
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
app_url = URI('http://localhost:3081')
sds_url = URI('http://localhost:4000')
user_app_ip = nil
ab_testing_app_ip = nil

catch(:break) do
  i = 0
  loop do
    begin
      Net::HTTP.start(app_url.host, app_url.port) do |http|
        response = http.get('/ip/user-app')
        user_app_ip = response.body
        response = http.get('/ip/ab-testing-app')
        ab_testing_app_ip = response.body
        throw(:break)
      end
    rescue EOFError, SystemCallError
      raise('Can not run the app container') if i == 19 # Overall retries end within 3.8s.
      puts 'waiting the app container to run...'
      sleep((2 * i) / 100.0)
      i += 1
    end
  end
end

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

puts 'ensure Envoy has no healty hosts'
Net::HTTP.start(envoy_url.host, envoy_url.port) do |http|
  response = http.get('/', Host: 'user')
  p response, response.body
  raise_error if response.code != '503'

  # Ensure healthy hosts on static host cluster
  response = http.get('/', Host: 'ab-testing')
  p response, response.body
  raise_error if response.code != '200'

  puts 'pass'
end

puts 'register hosts'
Net::HTTP.start(sds_url.host, sds_url.port) do |http|
  payload = { ip: user_app_ip, port: 8080, revision: 'a', tags: { az: 'b', region: 'ap-northeast-1', instance_id: 'test-instance' }.to_json }
  response = http.post('/v1/registration/user-development', payload.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&'))
  puts response.code, response.body
  raise_error if response.code != '200'

  response = http.get('/v1/registration/user-development')
  puts response.code, response.body
  raise_error if response.code != '200'
  raise_error if JSON.parse(response.body)['hosts'].size != 1

  puts 'pass'
end

puts 'ensure Envoy has healty hosts'
Net::HTTP.start(envoy_url.host, envoy_url.port) do |http|
  catch(:break) do
    i = 0
    loop do
      response = http.get('/', Host: 'user')
      response_ab = http.get('/', Host: 'ab-testing')
      throw(:break) if response.code == '200' && response_ab.code == '200'

      raise('Can not fetch healty upstreams') if i == 30
      puts 'waiting the envoy to fetch from SDS...'
      sleep((2 * i) / 100.0)
      i += 1
    end
  end

  response = http.get('/', Host: 'user')
  raise_error if response.code != '200'
  raise_error if response.body != 'GET,user,user'

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
    query = Rack::Utils.build_query(query: 'sum(envoy_cluster_upstream_rq_total{envoy_cluster_name!~"nginx|sds"}) by (envoy_cluster_name)')

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
