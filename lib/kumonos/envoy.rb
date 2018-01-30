module Kumonos
  # Generate envoy configuration.
  module Envoy
    class << self
      def generate(definition, cluster:, node:)
        EnvoyConfig.build(definition, cluster: cluster, node: node).to_h
      end
    end

    EnvoyConfig = Struct.new(:version, :discovery_service, :statsd, :listener, :admin, :cluster, :node, :eds) do
      class << self
        def build(h, cluster:, node:)
          discovery_service = DiscoverService.build(h.fetch('discovery_service'))
          eds = DiscoverService.build(h.fetch('eds'))
          new(
            h.fetch('version'),
            discovery_service,
            h['statsd'] ? h['statsd'].fetch('address') : nil,
            Listener.build(h.fetch('listener'), discovery_service),
            Admin.build(h.fetch('admin')),
            cluster,
            node,
            eds
          )
        end

        private

        def build_statsd_cluster(h)
          Cluster.new(
            'statsd',
            h.fetch('type'),
            h.fetch('tls'),
            h.fetch('connect_timeout_ms'),
            'round_robin',
            [{ 'url' => "tcp://#{h.fetch('address')}" }]
          )
        end
      end

      def to_h
        h = super
        h.delete(:version)
        h.delete(:discovery_service)
        h.delete(:eds)
        h.delete(:statsd)
        h.delete(:listener)
        h.delete(:cluster)
        h.delete(:node)
        h[:admin] = admin.to_h
        h[:static_resources] = {
          listeners: [listener.to_h],
          clusters: [discovery_service.cluster.to_h, eds.cluster.to_h]
        }
        h[:dynamic_resources] = {
          cds_config: {
            api_config_source: {
              cluster_names: [discovery_service.cluster.name],
              refresh_delay: {
                seconds: discovery_service.refresh_delay_ms / 1000.0
              }
            }
          },
          deprecated_v1: {
            sds_config: {
              api_config_source: {
                cluster_names: [eds.cluster.name],
                refresh_delay: {
                  seconds: eds.refresh_delay_ms / 1000.0
                }
              }
            },
          }
        }

        if statsd
          statsd_address, statsd_port = statsd.split(':')
          h[:stats_sinks] = [
            {
              name: 'envoy.dog_statsd',
              config: {
                address: {
                  socket_address: {
                    protocol: 'UDP',
                    address: statsd_address,
                    port_value: Integer(statsd_port)
                  }
                }
              }
            }
          ]
          h[:stats_config] = {
            use_all_default_tags: true,
            stats_tags: [
              { tag_name: 'service-cluster', fixed_value: cluster },
              { tag_name: 'service-node', fixed_value: node }
            ]
          }
        end

        h
      end
    end

    Listener = Struct.new(:address, :access_log_path, :discovery_service) do
      class << self
        def build(h, discovery_service)
          address = AddressParser.call(h.fetch('address'))
          new(address, h.fetch('access_log_path'), discovery_service)
        end
      end

      def to_h
        h = super
        h.delete(:discovery_service)
        h.delete(:access_log_path)
        h[:name] = 'egress'
        h[:filter_chains] = [
          {
            filters: [
              {
                name: 'envoy.http_connection_manager',
                config: {
                  codec_type: 'AUTO',
                  stat_prefix: 'egress_http',
                  access_log: [
                    {
                      name: 'envoy.file_access_log',
                      config: {
                        path: access_log_path
                      }
                    }
                  ],
                  rds: {
                    config_source: {
                      api_config_source: {
                        cluster_names: [discovery_service.cluster.name],
                        refresh_delay: {
                          seconds: discovery_service.refresh_delay_ms / 1000.0
                        }
                      }
                    },
                    route_config_name: DEFAULT_ROUTE_NAME
                  },
                  http_filters: [{ name: 'envoy.router' }]
                }
              }
            ]
          }
        ]
        h
      end
    end

    DiscoverService = Struct.new(:refresh_delay_ms, :cluster) do
      class << self
        def build(h)
          lb = h.fetch('lb')
          host, port = lb.split(':')
          cluster = Cluster.new(
            lb.split(':').first,
            'STRICT_DNS',
            h.fetch('tls'),
            h.fetch('connect_timeout_ms'),
            'ROUND_ROBIN',
            [{ 'socket_address' => { 'address' => host, 'port_value' => Integer(port) } }]
          )
          new(h.fetch('refresh_delay_ms'), cluster)
        end
      end

      def to_h
        h = super
        h[:cluster] = cluster.to_h
        h
      end
    end

    Cluster = Struct.new(:name, :type, :tls, :connect_timeout_ms, :lb_type, :hosts) do
      class << self
        def build(h)
          new(h.fetch('name'), h.fetch('type'), h.fetch('tls'), h.fetch('connect_timeout_ms'),
              h.fetch('lb_type'), h.fetch('hosts'))
        end
      end

      def to_h
        h = super
        h[:type] = type.upcase
        h.delete(:lb_type)
        h[:lb_policy] = lb_type.upcase
        h.delete(:tls)
        h[:tls_context] = {} if tls
        h.delete(:connect_timeout_ms)
        h[:connect_timeout] = {
          seconds: connect_timeout_ms / 1000.0
        }
        # Just work-around, it could be configurable.
        h[:dns_lookup_family] = 'V4_ONLY'
        h
      end
    end

    Admin = Struct.new(:address, :access_log_path) do
      class << self
        def build(h)
          address = AddressParser.call(h.fetch('address'))
          new(address, h.fetch('access_log_path'))
        end
      end
    end

    # Parse old address string
    module AddressParser
      def self.call(address)
        raise "invalid address given: #{address}" if address !~ %r{tcp://([^:]+):(\d+)}

        {
          socket_address: {
            address: Regexp.last_match(1),
            port_value: Integer(Regexp.last_match(2))
          }
        }
      end
    end
  end
end
