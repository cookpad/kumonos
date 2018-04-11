local circuit_breaker = import 'circuit_breaker.libsonnet';
local routes = import 'routes.libsonnet';

{
    version: 1,
    dependencies: [
        {
            name: "user",
            cluster_name: "user-development",
            lb: "user-app:8080",
            host_header: "user-service",
            tls: false,
            connect_timeout_ms: 250,
            circuit_breaker: circuit_breaker,
            routes: [routes.root],
        },
        {
            name: "ab-testing",
            cluster_name: "ab-testing-development",
            sds: true,
            tls: false,
            connect_timeout_ms: 250,
            circuit_breaker: circuit_breaker,
            routes: [routes.root],
        },
    ],
}
