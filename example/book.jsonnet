local circuit_breaker = import 'circuit_breaker.libsonnet';
local routes = import 'routes.libsonnet';

{
  version: 1,
  dependencies: [
    {
      name: 'user',
      cluster_name: 'user-development',
      lb: 'user-app:8080',
      host_header: 'user-service',
      tls: false,
      connect_timeout_ms: 250,
      circuit_breaker: circuit_breaker,
      routes: [routes.root],
    },
    {
      name: 'ab-testing',
      cluster_name: 'ab-testing-development',
      sds: true,
      tls: false,
      connect_timeout_ms: 250,
      circuit_breaker: circuit_breaker,
      outlier_detection: {
        consecutive_5xx: 3,
      },
      routes: [
        routes.root,
        {
          path: '/grpc.health.v1.Health/Check',
          method: 'POST',
          timeout_ms: 3000,
          retry_policy: {
            retry_on: '5xx,connect-failure,refused-stream,cancelled,deadline-exceeded,resource-exhausted',
            num_retries: 3,
            per_try_timeout_ms: 700,
          },
        },
      ],
    },
  ],
}
