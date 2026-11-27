# Stage Groups

Stages run one after another. The **groups** inside a stage run at the same time, each with its own worker count, rate, ramp and query mix, and each reported under its own name.

That's the shape of a real system: several classes of client with different concurrency and pacing, all hitting one database. A single worker pool and one `weights` map can only approximate it - with groups, a slow analytical query can't eat the OLTP budget and a background reaper keeps its cadence whatever the rest of the workload is doing.

```edg
stages {
  warmup(duration: 10s) {
    shoppers(workers: 2, weights: { check_balance: 100 })
  }

  peak(duration: 30s) {
    shoppers(workers: 20, ramp_duration: 5s, weights: { check_balance: 60, make_transfer: 40 })
    analysts(workers: 2, qps: 5, weights: { daily_totals: 100 })
    reaper(workers: 1, qps: 1, weights: { credit_account: 100 })
  }

  cooldown(duration: 10s) {
    shoppers(workers: 2, weights: { check_balance: 100 })
  }
}
```

During `peak`, 23 workers run at once:

- **shoppers** - 20 workers on the OLTP mix, unthrottled, ramping up over 5s from the 2 the lane was running during warmup
- **analysts** - 2 workers on the reporting query, capped at 5 queries per second between them
- **reaper** - 1 worker crediting an account once a second

## Options

A group takes every stage option except `duration`, which the enclosing stage owns:

| Option | Description |
|---|---|
| `workers` | Concurrent workers in this lane. Defaults to 1. |
| `qps` | Rate limit for this lane alone. Accepts a literal, `ramp(start, end, duration)`, or `signal('name', peak: N)`. |
| `ramp_duration` | Ramp this lane up over the given period. Must be less than the stage's `duration`. |
| `weights` | This lane's query mix. Falls back to the top-level `weights` when omitted. |

A stage that declares groups must not also declare `workers`, `qps`, `ramp_duration` or `weights` - those describe the single lane an ungrouped stage runs as.

## Reporting

A grouped query is reported as `group.query`, so two lanes running the same query keep their own counts, latencies and error rates:

```
QUERY                   COUNT   ERRORS  p90    p95    p99    QPS
analysts.daily_totals   150     0       31ms   34ms   41ms   5.0
reaper.credit_account   30      0       2ms    2ms    3ms    1.0
shoppers.check_balance  184210  0       1ms    2ms    4ms    6140.3
shoppers.make_transfer  122807  0       2ms    3ms    9ms    4093.5
```

Expectations address the same name:

```edg
expect {
  oltp_is_fast    shoppers.check_balance.p99 < 100
  reports_finish  analysts.daily_totals.p99 < 5000
}
```

A lane carries across stages by name: the `shoppers` group in `peak` ramps from whatever `shoppers` was running in `warmup`, not from one worker.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Run

```sh
edg all \
--driver pgx \
--config examples/stage_groups/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
--tui \
--pause
```
