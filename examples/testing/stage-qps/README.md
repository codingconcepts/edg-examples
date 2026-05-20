# Stage QPS Example

Demonstrates using stages with QPS rate limiting to control throughput at each phase of a workload.

## What it does

This workload runs four stages against a CockroachDB `users` table:

| Stage | Workers | Duration | QPS | Purpose |
|---|---|---|---|---|
| warmup | 2 | 30s | unlimited | Warm connection pools and caches |
| ramp | 10 | 1m | 200 | Gradually introduce load |
| sustain | 10 | 2m | 500 | Hold at target throughput |
| cool_down | 2 | 30s | unlimited | Drain gracefully |

When `qps` is set on a stage, workers collectively throttle to that rate. When omitted, workers run as fast as possible.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

```sh
edg all \
  --driver pgx \
  --config examples/testing/stage-qps/crdb.edg \
  --url "postgres://root@localhost:26257?sslmode=disable" \
  --metrics-samples 500
```

## Observe

Add `--metrics-addr :9090` to expose Prometheus metrics during the run and verify QPS matches the target at each stage.
