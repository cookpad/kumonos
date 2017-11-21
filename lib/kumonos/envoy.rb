module Kumonos
  # Generate envoy configuration.
  module Envoy
    class << self
      def generate(definition)
        EnvoyConfig.build(definition).to_h
      end
    end

    EnvoyConfig = Struct.new(:version, :discovery_service, :statsd, :listener, :admin) do
      class << self
        def build(h)
          discovery_service = DiscoverService.build(h.fetch('discovery_service'))
          new(
            h.fetch('version'),
            discovery_service,
            h['statsd'] ? build_statsd_cluster(h['statsd']) : nil,
            Listener.build(h.fetch('listener'), discovery_service),
            Admin.build(h.fetch('admin'))
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
        h.delete(:statsd)
        h.delete(:listener)
        h[:admin] = admin.to_h
        h[:listeners] = [listener.to_h]
        h[:cluster_manager] = { cds: discovery_service.to_h, clusters: [] }

        if statsd
          h[:statsd_tcp_cluster_name] = statsd.name
          h[:cluster_manager][:clusters] << statsd.to_h
        end

        h
      end
    end

    Listener = Struct.new(:address, :access_log_path, :discovery_service) do
      class << self
        def build(h, discovery_service)
          new(h.fetch('address'), h.fetch('access_log_path'), discovery_service)
        end
      end

      def to_h
        h = super
        h.delete(:discovery_service)
        h.delete(:access_log_path)
        h[:filters] = [
          {
            type: 'read',
            name: 'http_connection_manager',
            config: {
              codec_type: 'auto',
              stat_prefix: 'egress_http',
              access_log: [{ path: access_log_path }],
              rds: {
                cluster: discovery_service.cluster.name,
                route_config_name: DEFAULT_ROUTE_NAME,
                refresh_delay_ms: discovery_service.refresh_delay_ms
              },
              filters: [{ type: 'decoder', name: 'router', config: {} }]
            }
          }
        ]
        h
      end
    end

    DiscoverService = Struct.new(:refresh_delay_ms, :cluster) do
      class << self
        def build(h)
          lb = h.fetch('lb')
          cluster = Cluster.new(
            lb.split(':').first,
            'strict_dns',
            h.fetch('tls'),
            h.fetch('connect_timeout_ms'),
            'round_robin',
            [{ 'url' => "tcp://#{lb}" }]
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
          new(h.fetch('name'), h.fetch('type'), h.fetch('tls'), h.fetch('connect_timeout_ms'), h.fetch('lb_type'), h.fetch('hosts'))
        end
      end

      def to_h
        h = super
        h.delete(:tls)
        h[:ssl_context] = {} if tls
        h
      end
    end

    Admin = Struct.new(:address, :access_log_path) do
      class << self
        def build(h)
          new(h.fetch('address'), h.fetch('access_log_path'))
        end
      end
    end
  end
end
