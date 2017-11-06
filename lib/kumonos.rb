require 'json'
require 'yaml'
require 'kumonos/version'

# Kumonos
module Kumonos
  class << self
    def generate(config)
      virtual_hosts = config['services'].map { |s| service_to_vhost(s) }
      clusters = config['services'].map { |s| service_to_cluster(s) }
      {
        listeners: [
          {
            address: 'tcp://0.0.0.0:9211',
            filters: [
              type: 'read',
              name: 'http_connection_manager',
              config: {
                codec_type: 'auto',
                stat_prefix: 'ingress_http',
                access_log: [{ path: '/dev/stdout' }],
                route_config: {
                  virtual_hosts: virtual_hosts
                },
                filters: [{ type: 'decoder', name: 'router', config: {} }]
              }
            ]
          }
        ],
        admin: {
          access_log_path: '/dev/stdout',
          address: 'tcp://0.0.0.0:9901'
        },
        cluster_manager: {
          clusters: clusters
        }
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

    # Split route config to apply retry config only to GET/HEAD requests.
    def split_route(route, name)
      base = {
        prefix: route['prefix'],
        timeout_ms: route['timeout_ms'],
        cluster: name
      }
      with_retry = base.merge(
        retry_policy: route['retry_policy'],
        headers: [{ name: ':method', value: '(GET|HEAD)', regex: true }]
      )
      [with_retry, base]
    end

    def service_to_cluster(service)
      {
        name: service['name'],
        connect_timeout_ms: service['connect_timeout_ms'],
        type: 'logical_dns',
        lb_type: 'round_robin',
        hosts: [{ url: "tcp://#{service['lb']}" }],
        circuit_breakers: {
          default: service['circuit_breaker']
        }
      }
    end
  end
end
