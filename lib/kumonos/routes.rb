module Kumonos
  # Generate routes configuration
  module Routes
    class << self
      def generate(definition)
        {
          validate_clusters: false,
          virtual_hosts: definition['dependencies'].map { |s| service_to_vhost(s) }
        }
      end

      private

      def service_to_vhost(service)
        name = service['name']
        {
          name: name,
          domains: [name],
          routes: service['routes'].flat_map { |r| split_route(r, name) }
        }
      end

      # Split route definition to apply retry definition only to GET/HEAD requests.
      def split_route(route, name)
        base = {
          prefix: route['prefix'],
          timeout_ms: route['timeout_ms'],
          auto_host_rewrite: true,
          cluster: name
        }
        with_retry = base.merge(
          retry_policy: route['retry_policy'],
          headers: [{ name: ':method', value: '(GET|HEAD)', regex: true }]
        )
        [with_retry, base]
      end
    end
  end
end
