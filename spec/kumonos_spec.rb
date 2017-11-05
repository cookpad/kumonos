RSpec.describe Kumonos do
  it 'has a version number' do
    expect(Kumonos::VERSION).not_to be nil
  end

  it 'generates vaild config' do
    filename = File.expand_path('../example/book.yml', __dir__)
    config = YAML.load_file(filename)
    out = JSON.dump(Kumonos.generate(config))

    expect(out).to be_json_as(
      {
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
                  route_config: {
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
                  },
                  filters: [
                    {
                      type: 'decoder',
                      name: 'router',
                      config: {},
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
        cluster_manager: {
          clusters: [
            {
              name: 'user',
              connect_timeout_ms: 250,
              type: 'logical_dns',
              lb_type: 'round_robin',
              hosts: [{url: 'tcp://user:8080'}]
            },
            {
              name: 'ab-testing',
              connect_timeout_ms: 250,
              type: 'logical_dns',
              lb_type: 'round_robin',
              hosts: [{url: 'tcp://ab-testing:8080'}]
            }
          ]
        }
      }
    )
  end
end
