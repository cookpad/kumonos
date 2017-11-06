module Kumonos
  # Generate clusters configuration.
  module Clusters
    class << self
      def generate(definition)
        {
          clusters: definition['dependencies'].map { |s| service_to_cluster(s) }
        }
      end

      private

      def service_to_cluster(service)
        out = {
          name: service['name'],
          connect_timeout_ms: service['connect_timeout_ms'],
          type: 'strict_dns',
          lb_type: 'round_robin',
          hosts: [{ url: "tcp://#{service['lb']}" }],
          circuit_breakers: {
            default: service['circuit_breaker']
          }
        }
        out[:ssl_context] = {} if service['tls']
        out
      end
    end
  end
end
