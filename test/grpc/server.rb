lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'grpc'
require 'health_services_pb'

class HealthCheckServer < Grpc::Health::V1::Health::Service
  def check(_req, _unused_call)
    Grpc::Health::V1::HealthCheckResponse.new(
      status: Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING
    )
  end
end

port = (ENV['PORT'] || 8080)

s = GRPC::RpcServer.new
s.add_http2_port("0.0.0.0:#{port}", :this_port_is_insecure)
s.handle(HealthCheckServer)

puts 'Running server...'
s.run
