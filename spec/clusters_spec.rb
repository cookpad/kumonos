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

  let(:definition_with_tls) do
    filename = File.expand_path('../example/example-with-tls.yml', __dir__)
    YAML.load_file(filename)
  end

  specify '.generate with tls' do
    out = JSON.dump(Kumonos::Clusters.generate(definition_with_tls))
    expect(out).to be_json_as(
      clusters: [
        {
          name: 'example',
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
