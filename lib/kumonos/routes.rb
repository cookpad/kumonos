# frozen_string_literal: true

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
          host_header = h['host_header']
          routes = h.fetch('routes').map { |r| Route.build(r, cluster_name, host_header) }
          new(name, [name], routes)
        end
      end

      def to_h
        h = super
        h[:routes] = routes.flat_map do |r|
          # i.e. retry with gRPC request (HTTP POST)
          if r.method
            [r.to_h_with_retry]
          else
            [r.to_h_with_retry, r.to_h]
          end
        end
        h
      end
    end

    Route = Struct.new(:prefix, :path, :method, :cluster, :timeout_ms, :retry_policy, :host_header) do
      class << self
        def build(h, cluster, host_header)
          new(h['prefix'], h['path'], h['method'], cluster, h.fetch('timeout_ms'),
              RetryPolicy.build(h.fetch('retry_policy')), host_header)
        end
      end

      def to_h
        h = super
        h.delete(:retry_policy)
        h.delete(:host_header)
        h.delete(:method)

        if prefix
          h.delete(:path)
          h[:prefix] = prefix
        elsif path
          h.delete(:prefix)
          h[:path] = path
        else
          raise '`path` or `prefix` is required'
        end

        if host_header
          h[:host_rewrite] = host_header
        else
          h[:auto_host_rewrite] = true
        end
        h
      end

      ALLOWED_METHODS = %w[GET HEAD POST PUT DELETE].freeze
      def to_h_with_retry
        h = to_h
        h[:retry_policy] = retry_policy.to_h

        if method
          m = method.upcase
          unless ALLOWED_METHODS.include?(m)
            raise "method must be one of #{ALLOWED_METHODS.join(',')}: given `#{m}`"
          end

          h[:headers] = [{ name: ':method', value: m, regex: false }]
        else
          h[:headers] = [{ name: ':method', value: '(GET|HEAD)', regex: true }]
        end

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
