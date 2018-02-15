RSpec.describe Kumonos::Clusters do
  let(:definition) do
    filename = File.expand_path('../example/book.yml', __dir__)
    YAML.load_file(filename)
  end

  specify '.generate' do
    out = JSON.dump(Kumonos::Clusters.generate(definition))
    expect(out).to be_json_as(
      clusters: [
        {
          name: 'user-development',
          connect_timeout_ms: 250,
          type: 'strict_dns',
          hosts: [{ url: 'tcp://user-app:8080' }],
          lb_type: 'round_robin',
          circuit_breakers: {
            default: {
              max_connections: 64,
              max_pending_requests: 128,
              max_retries: 3
            }
          }
        },
        {
          name: 'ab-testing-development',
          connect_timeout_ms: 250,
          type: 'sds',
          service_name: 'ab-testing-development',
          features: 'http2',
          lb_type: 'round_robin',
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

  let(:definition_with_tls) do
    filename = File.expand_path('../example/example-with-tls.yml', __dir__)
    YAML.load_file(filename)
  end

  specify '.generate with tls' do
    out = JSON.dump(Kumonos::Clusters.generate(definition_with_tls))
    expect(out).to be_json_as(
      clusters: [
        {
          name: 'example-development',
          connect_timeout_ms: 250,
          type: 'strict_dns',
          lb_type: 'round_robin',
          ssl_context: {},
          hosts: [{ url: 'tcp://example.com:443' }],
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
