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

Apply license (if using `--tui` flag)

```sh
eval "export $(dotenvx get --format shell)"
```

Start cluster

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Run

```sh
edg all \
  --driver pgx \
  --config examples/testing/stage-qps/crdb.edg \
  --url "postgres://root@localhost:26257?sslmode=disable" \
  --metrics-samples 500 \
  --tui
```

### Observe

Add `--metrics-addr :9090` to expose Prometheus metrics during the run and verify QPS matches the target at each stage.

### Teardown

Stop cluster

```sh
docker compose -f infra/compose_crdb.yml down
```