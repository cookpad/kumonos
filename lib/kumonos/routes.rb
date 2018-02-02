module Kumonos
  # Generate routes configuration
  module Routes
    class << self
      def generate(definition)
        {
          validate_clusters: false,
          virtual_hosts: definition['dependencies'].map { |s| Vhost.build(s).to_h }
        }
      end
    end

    Vhost = Struct.new(:name, :domains, :routes) do
      class << self
        def build(h)
          name = h.fetch('name')
          cluster_name = h.fetch('cluster_name')
          routes = h.fetch('routes').map { |r| Route.build(r, cluster_name) }
          new(name, [name], routes)
        end
      end

      def to_h
        h = super
        h[:routes] = routes.flat_map { |r| [r.to_h_with_retry, r.to_h] }
        h
      end
    end

    Route = Struct.new(:prefix, :cluster, :timeout_ms, :retry_policy) do
      class << self
        def build(h, cluster)
          new(h.fetch('prefix'), cluster, h.fetch('timeout_ms'), RetryPolicy.build(h.fetch('retry_policy')))
        end
      end

      def to_h
        h = super
        h.delete(:retry_policy)
        h[:auto_host_rewrite] = true
        h
      end

      def to_h_with_retry
        h = to_h
        h[:retry_policy] = retry_policy.to_h
        h[:headers] = [{ name: ':method', value: '(GET|HEAD)', regex: true }]
        h
      end
    end

    RetryPolicy = Struct.new(:retry_on, :num_retries, :per_try_timeout_ms) do
      class << self
        def build(h)
          new(h.fetch('retry_on'), h.fetch('num_retries'), h.fetch('per_try_timeout_ms'))
        end
      end
    end
  end
end
