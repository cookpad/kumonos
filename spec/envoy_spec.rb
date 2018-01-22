RSpec.describe Kumonos::Envoy do
  let(:definition) do
    YAML.load_file(File.expand_path('../example/envoy_config.yml', __dir__))
  end

  specify 'generate' do
    out = JSON.dump(Kumonos::Envoy.generate(definition))
    expect(out).to be_json_as(
      admin: {
        access_log_path: '/dev/stdout',
        address: {
          socket_address: { address: '0.0.0.0', port_value: 9901 }
        }
      },
      stats_sinks: [
        {
          name: 'envoy.dog_statsd',
          config: {
            address: {
              socket_address: {
                protocol: 'UDP',
                address: 'statsd-exporter',
                port_value: 9125
              }
            }
          }
        }
      ],
      stats_config: {
        use_all_default_tags: true,
        stats_tags: []
      },
      static_resources: {
        listeners: [
          {
            name: 'egress',
            address: {
              socket_address: { address: '0.0.0.0', port_value: 9211 }
            },
            filter_chains: [
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
                            path: '/dev/stdout'
                          }
                        }
                      ],
                      rds: {
                        config_source: {
                          api_config_source: {
                            cluster_names: ['nginx'],
                            refresh_delay: {
                              seconds: 30
                            }
                          }
                        },
                        route_config_name: 'default'
                      },
                      http_filters: [{ name: 'envoy.router' }]
                    }
                  }
                ]
              }
            ]
          }
        ],
        clusters: [
          {
            name: 'nginx',
            connect_timeout: {
              seconds: 1
            },
            type: 'STRICT_DNS',
            lb_policy: 'ROUND_ROBIN',
            hosts: [
              { socket_address: { address: 'nginx', port_value: 80 } }
            ]
          }
        ]
      },
      dynamic_resources: {
        cds_config: {
          api_config_source: {
            cluster_names: ['nginx'],
            refresh_delay: {
              seconds: 30
            }
          }
        }
      }
    )
  end

  specify '.generate with ds with TLS' do
    definition['discovery_service']['tls'] = true
    out = Kumonos::Envoy.generate(definition)
    ds_cluster = out.fetch(:static_resources).fetch(:clusters)[0]
    expect(JSON.dump(ds_cluster)).to be_json_as(
      name: 'nginx',
      type: 'STRICT_DNS',
      tls_context: {},
      connect_timeout: {
        seconds: 1.0
      },
      lb_policy: 'ROUND_ROBIN',
      hosts: [
        { socket_address: { address: 'nginx', port_value: 80 } }
      ]
    )
  end

  specify '.generate without statsd' do
    definition.delete('statsd')
    out = Kumonos::Envoy.generate(definition)
    expect(out).not_to have_key(:stats_sinks)
    expect(out).not_to have_key(:stats_config)
  end
end
