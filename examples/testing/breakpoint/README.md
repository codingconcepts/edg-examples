# Breakpoint Testing Example

Demonstrates using `edg perf breakpoint` to find the point at which a CockroachDB cluster starts to degrade under increasing load.

## What it does

The breakpoint test:

1. Seeds a `users` table with 5,000 rows
2. Starts with 1 worker running reads and writes
3. Adds a worker every 10 seconds
4. Warns when p99 latency or per-worker QPS degrades by 30% from the baseline
5. Stops when p99 exceeds 100ms


## Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

## Prep

Seed the database first (breakpoint only runs the `run` section):

```sh
edg up \
  --driver pgx \
  --config examples/testing/breakpoint/crdb.edg \
  --url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
  --driver pgx \
  --config examples/testing/breakpoint/crdb.edg \
  --url "postgres://root@localhost:26257?sslmode=disable"
```

## Run

```sh
edg perf breakpoint \
  --driver pgx \
  --config examples/testing/breakpoint/crdb.edg \
  --url "postgres://root@localhost:26257?sslmode=disable" \
  --ramp-interval 5s \
  --threshold 50 \
  --stop-p99 100ms \
  --duration 5m
```

## Output

edg prints live stats each second and logs warnings as metrics degrade:

```
WARN p99 degraded baseline=2ms current=4ms change=100.0%
INFO breakpoint reached reason="p99 120ms exceeds --stop-p99 100ms" workers=47
```

The final worker count tells you how many concurrent workers your database handled before latency became unacceptable.

## Teardown

```sh
edg deseed \
  --driver pgx \
  --config examples/testing/breakpoint/crdb.edg \
  --url "postgres://root@localhost:26257?sslmode=disable"

edg down \
  --driver pgx \
  --config examples/testing/breakpoint/crdb.edg \
  --url "postgres://root@localhost:26257?sslmode=disable"
```
