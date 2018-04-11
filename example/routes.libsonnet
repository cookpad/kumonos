{
    root: {
        prefix: "/",
        timeout_ms: 3000,
        retry_policy: {
            retry_on: "5xx,connect-failure,refused-stream",
            num_retries: 3,
            per_try_timeout_ms: 1000,
        },
    },
}
