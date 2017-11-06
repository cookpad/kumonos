RSpec.describe Kumonos do
  it 'has a version number' do
    expect(Kumonos::VERSION).not_to be nil
  end

  let(:config) do
    filename = File.expand_path('../example/book.yml', __dir__)
    YAML.load_file(filename)
  end

  it 'generates vaild config' do
    out = JSON.dump(Kumonos.generate(config, 'test'))
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
                stat_prefix: 'ingress_http',
                access_log: [{ path: '/dev/stdout' }],
                rds: {
                  cluster: 'nginx',
                  route_config_name: 'test',
                  refresh_delay_ms: 30000
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
            connect_timeout_ms: 250,
            type: 'strict_dns',
            lb_type: 'round_robin',
            hosts: [{ url: 'tcp://socat:2000' }]
          }
        ],
        cds: {
          cluster: {
            name: 'nginx', # TODO
            type: 'strict_dns',
            connect_timeout_ms: 250,
            lb_type: 'round_robin',
            hosts: [
              { url: 'tcp://nginx:80' } # TODO
            ]
          },
          refresh_delay_ms: 30000 # TODO
        }
      }
    )
  end

  specify 'generate_routes' do
    out = JSON.dump(Kumonos.generate_routes(config))

    expect(out).to be_json_as(
      validate_clusters: false,
      virtual_hosts: [
        {
          name: 'user',
          domains: ['user'],
          routes: [
            {
              prefix: '/',
              timeout_ms: 3000,
              cluster: 'user',
              retry_policy: {
                retry_on: '5xx,connect-failure,refused-stream',
                num_retries: 3,
                per_try_timeout_ms: 250
              },
              headers: [
                {
                  name: ':method',
                  value: '(GET|HEAD)',
                  regex: true
                }
              ]
            },
            {
              prefix: '/',
              timeout_ms: 3000,
              cluster: 'user'
            }
          ]
        },
        {
          name: 'ab-testing',
          domains: ['ab-testing'],
          routes: [
            {
              prefix: '/',
              timeout_ms: 3000,
              cluster: 'ab-testing',
              retry_policy: {
                retry_on: '5xx,connect-failure,refused-stream',
                num_retries: 3,
                per_try_timeout_ms: 250
              },
              headers: [
                {
                  name: ':method',
                  value: '(GET|HEAD)',
                  regex: true
                }
              ]
            },
            {
              prefix: '/',
              timeout_ms: 3000,
              cluster: 'ab-testing'
            }
          ]
        }
      ]
    )
  end

  specify 'generate_clusters' do
    out = JSON.dump(Kumonos.generate_clusters(config))
    expect(out).to be_json_as(
      clusters: [
        {
          name: 'user',
          connect_timeout_ms: 250,
          type: 'strict_dns',
          lb_type: 'round_robin',
          hosts: [{ url: 'tcp://user:8080' }],
          circuit_breakers: {
            default: {
              max_connections: 64,
              max_pending_requests: 128,
              max_retries: 3
            }
          }
        },
        {
          name: 'ab-testing',
          connect_timeout_ms: 250,
          type: 'strict_dns',
          lb_type: 'round_robin',
          hosts: [{ url: 'tcp://ab-testing:8080' }],
          circuit_breakers: {
            default: {
              max_connections: 64,
              max_pending_requests: 128,
              max_retries: 3
            }
          }
        }
      ]
    )
  end
end
