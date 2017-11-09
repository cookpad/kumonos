RSpec.describe Kumonos::Routes do
  let(:definition) do
    filename = File.expand_path('../example/book.yml', __dir__)
    YAML.load_file(filename)
  end

  specify '.generate' do
    out = JSON.dump(Kumonos::Routes.generate(definition))

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
              auto_host_rewrite: true,
              cluster: 'user',
              retry_policy: {
                retry_on: '5xx,connect-failure,refused-stream',
                num_retries: 3,
                per_try_timeout_ms: 1_000
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
              auto_host_rewrite: true,
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
              auto_host_rewrite: true,
              cluster: 'ab-testing',
              retry_policy: {
                retry_on: '5xx,connect-failure,refused-stream',
                num_retries: 3,
                per_try_timeout_ms: 1_000
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
              auto_host_rewrite: true,
              cluster: 'ab-testing'
            }
          ]
        }
      ]
    )
  end
end
