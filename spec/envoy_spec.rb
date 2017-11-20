RSpec.describe Kumonos::Envoy do
  let(:definition) do
    YAML.load_file(File.expand_path('../example/envoy_config.yml', __dir__))
  end

  specify 'generate' do
    out = JSON.dump(Kumonos::Envoy.generate(definition))
    expect(out).to be_json_as(
      listeners: [
        {
          address: 'tcp://0.0.0.0:9211',
          filters: [
            {
              type: 'read',
              name: 'http_connection_manager',
              config: {
                codec_type: 'auto',
                stat_prefix: 'egress_http',
                access_log: [{ path: '/dev/stdout' }],
                rds: {
                  cluster: 'discovery_service',
                  route_config_name: 'default',
                  refresh_delay_ms: 30_000
                },
                filters: [
                  {
                    type: 'decoder',
                    name: 'router',
                    config: {}
                  }
                ]
              }
            }
          ]
        }
      ],
      admin: {
        access_log_path: '/dev/stdout',
        address: 'tcp://0.0.0.0:9901'
      },
      statsd_tcp_cluster_name: 'statsd',
      cluster_manager: {
        clusters: [
          {
            name: 'statsd',
            connect_timeout_ms: 1_000,
            type: 'strict_dns',
            lb_type: 'round_robin',
            hosts: [{ url: 'tcp://relay:2000' }]
          }
        ],
        cds: {
          cluster: {
            name: 'discovery_service',
            type: 'strict_dns',
            connect_timeout_ms: 1_000,
            lb_type: 'round_robin',
            hosts: [
              { url: 'tcp://nginx:80' }
            ]
          },
          refresh_delay_ms: 30_000
        }
      }
    )
  end

  specify '.generate with ds with TLS' do
    definition['discovery_service']['tls'] = true
    out = Kumonos::Envoy.generate(definition)
    ds_cluster = out.fetch(:cluster_manager).fetch(:cds).fetch(:cluster)
    expect(JSON.dump(ds_cluster)).to be_json_as(
      name: 'discovery_service',
      type: 'strict_dns',
      ssl_context: {},
      connect_timeout_ms: 1_000,
      lb_type: 'round_robin',
      hosts: [
        { url: 'tcp://nginx:80' }
      ]
    )
  end

  specify '.generate without statsd' do
    definition.delete('statsd')
    out = Kumonos::Envoy.generate(definition)
    expect(out).not_to have_key(:statsd_tcp_cluster_name)
    expect(out[:cluster_manager][:clusters]).to be_empty
  end
end
