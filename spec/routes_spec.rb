# frozen_string_literal: true

require 'jsonnet'

RSpec.describe Kumonos::Routes do
  let(:definition) do
    filename = File.expand_path('../example/book.jsonnet', __dir__)
    Jsonnet.load(filename)
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
              path: '/ping',
              timeout_ms: 100,
              host_rewrite: 'user-service',
              cluster: 'user-development'
            },
            {
              prefix: '/',
              timeout_ms: 3000,
              host_rewrite: 'user-service',
              cluster: 'user-development',
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
              host_rewrite: 'user-service',
              cluster: 'user-development'
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
              cluster: 'ab-testing-development',
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
              cluster: 'ab-testing-development'
            },
            {
              path: '/grpc.health.v1.Health/Check',
              timeout_ms: 3000,
              auto_host_rewrite: true,
              cluster: 'ab-testing-development',
              retry_policy: {
                retry_on: '5xx,connect-failure,refused-stream,cancelled,deadline-exceeded,resource-exhausted',
                num_retries: 3,
                per_try_timeout_ms: 700
              },
              headers: [
                {
                  name: ':method',
                  value: 'POST',
                  regex: false
                }
              ]
            }
          ]
        }
      ]
    )
  end
end
