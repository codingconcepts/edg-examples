# Stages with Per-Stage Run Weights

An example of staged execution where each stage can override the workload mix. This lets you shift the traffic shape alongside the worker count - e.g., ramp-up is read-heavy, steady-state is write-heavy.

When a stage defines its own `run_weights`, workers in that stage use those weights. When a stage omits `run_weights`, it falls back to the top-level `run_weights`. When neither exists, all run items execute sequentially.

```yaml
stages:
  - name: ramp
    workers: 1
    duration: 10s
    run_weights:
      check_balance: 90
      credit_account: 5
      make_transfer: 5
  - name: steady
    workers: 10
    duration: 30s
    run_weights:
      check_balance: 50
      credit_account: 5
      make_transfer: 45
  - name: cooldown
    workers: 2
    duration: 10s
    # Falls back to top-level run_weights

run_weights:
  check_balance: 70
  credit_account: 10
  make_transfer: 20
```

In this example:

- **ramp** - 1 worker, 90% reads, 5% credits, 5% transfers
- **steady** - 10 workers, 50% reads, 5% credits, 45% transfers
- **cooldown** - 2 workers, inherits top-level weights (70/10/20)

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

```sh
go run ./cmd/edg all \
--driver pgx \
--config _examples/stages_run_weights/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```
