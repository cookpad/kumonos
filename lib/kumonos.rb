require 'json'
require 'yaml'

require 'kumonos/version'
require 'kumonos/schemas'
require 'kumonos/configuration'
require 'kumonos/routes'

# Kumonos
module Kumonos
  DEFAULT_ROUTE_NAME = 'default'.freeze

  class << self
    def generate(config)
      {
        listeners: [
          {
            address: config.listener.fetch(:address),
            filters: [
              type: 'read',
              name: 'http_connection_manager',
              config: {
                codec_type: 'auto',
                stat_prefix: 'ingress_http',
                access_log: [{ path: config.listener.fetch(:access_log_path) }],
                rds: {
                  cluster: config.ds.fetch(:name),
                  route_config_name: DEFAULT_ROUTE_NAME,
                  refresh_delay_ms: config.ds.fetch(:refresh_delay_ms)
                },
                filters: [{ type: 'decoder', name: 'router', config: {} }]
              }
            ]
          }
        ],
        admin: {
          access_log_path: config.admin.fetch(:access_log_path),
          address: config.admin.fetch(:address)
        },
        statsd_tcp_cluster_name: config.statsd.fetch(:name),
        cluster_manager: {
          clusters: [config.statsd],
          cds: {
            cluster: config.ds.fetch(:cluster),
            refresh_delay_ms: config.ds.fetch(:refresh_delay_ms)
          }
        }
      }
    end

    def generate_clusters(definition)
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
