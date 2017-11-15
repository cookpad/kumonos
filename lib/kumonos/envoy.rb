module Kumonos
  # Generate envoy configuration.
  module Envoy
    class << self
      def generate(definition)
        EnvoyConfig.build(definition).to_h
      end
    end

    EnvoyConfig = Struct.new(:version, :ds, :statsd, :listener, :admin) do
      class << self
        def build(h)
          ds = DiscoverService.build(h.fetch('ds'))
          new(
            h.fetch('version'),
            ds,
            h['statsd'] ? Cluster.build(h['statsd']) : nil,
            Listener.build(h.fetch('listener'), ds),
            Admin.build(h.fetch('admin'))
          )
        end
      end

      def to_h
        h = super
        h.delete(:version)
        h.delete(:ds)
        h.delete(:statsd)
        h.delete(:listener)
        h[:admin] = admin.to_h
        h[:listeners] = [listener.to_h]
        h[:cluster_manager] = { cds: ds.to_h, clusters: [] }

        if statsd
          h[:statsd_tcp_cluster_name] = statsd.name
          h[:cluster_manager][:clusters] << statsd.to_h
        end

        h
      end
    end

    Listener = Struct.new(:address, :access_log_path, :ds) do
      class << self
        def build(h, ds)
          new(h.fetch('address'), h.fetch('access_log_path'), ds)
        end
      end

      def to_h
        h = super
        h.delete(:ds)
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
                cluster: ds.cluster.name,
                route_config_name: DEFAULT_ROUTE_NAME,
                refresh_delay_ms: ds.refresh_delay_ms
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
          new(h.fetch('refresh_delay_ms'), Cluster.build(h.fetch('cluster')))
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
        if tls
          cluster[:ssl_context] = {}
        else
          h.delete(:tls)
        end
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
