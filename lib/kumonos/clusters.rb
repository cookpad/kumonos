module Kumonos
  # Generate clusters configuration.
  module Clusters
    class << self
      def generate(definition)
        {
          clusters: definition['dependencies'].map { |s| Cluster.build(s).to_h }
        }
      end
    end

    Cluster = Struct.new(:name, :connect_timeout_ms, :lb, :tls, :circuit_breaker, :use_sds) do
      class << self
        def build(h)
          use_sds = h.fetch('sds', false)
          lb = use_sds ? nil : h.fetch('lb')

          new(
            h.fetch('cluster_name'),
            h.fetch('connect_timeout_ms'),
            lb,
            h.fetch('tls'),
            CircuitBreaker.build(h.fetch('circuit_breaker')),
            use_sds
          )
        end
      end

      def to_h
        h = super

        h.delete(:lb)
        h.delete(:use_sds)
        if use_sds
          h[:type] = 'sds'
          h[:service_name] = name
        else
          h[:type] = 'strict_dns'
          h[:hosts] = [{ url: "tcp://#{lb}" }]
        end

        h[:lb_type] = 'round_robin'
        h.delete(:tls)
        h[:ssl_context] = {} if tls

        h.delete(:circuit_breaker)
        h[:circuit_breakers] = { default: circuit_breaker.to_h }

        h
      end
    end

    CircuitBreaker = Struct.new(:max_connections, :max_pending_requests, :max_retries) do
      class << self
        def build(h)
          new(h.fetch('max_connections'), h.fetch('max_pending_requests'), h.fetch('max_retries'))
        end
      end
    end
  end
end
