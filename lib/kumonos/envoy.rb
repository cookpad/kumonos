module Kumonos
  # Generate envoy configuration.
  module Envoy
    class << self
      # @param [Kumonos::EnvoyDefinition] definition
      # @return [Hash] envoy configuration hash
      def generate(definition)
        {
          listeners: [
            {
              address: definition.listener.fetch(:address),
              filters: [
                type: 'read',
                name: 'http_connection_manager',
                config: {
                  codec_type: 'auto',
                  stat_prefix: 'ingress_http',
                  access_log: [{ path: definition.listener.fetch(:access_log_path) }],
                  rds: {
                    cluster: definition.ds.fetch(:name),
                    route_config_name: DEFAULT_ROUTE_NAME,
                    refresh_delay_ms: definition.ds.fetch(:refresh_delay_ms)
                  },
                  filters: [{ type: 'decoder', name: 'router', config: {} }]
                }
              ]
            }
          ],
          admin: {
            access_log_path: definition.admin.fetch(:access_log_path),
            address: definition.admin.fetch(:address)
          },
          statsd_tcp_cluster_name: definition.statsd.fetch(:name),
          cluster_manager: {
            clusters: [definition.statsd],
            cds: {
              cluster: definition.ds.fetch(:cluster),
              refresh_delay_ms: definition.ds.fetch(:refresh_delay_ms)
            }
          }
        }
      end
    end
  end
end
