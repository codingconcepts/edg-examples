# Capture

Generate an edg workload config from real query statistics. This example uses CockroachDB's built-in TPC-C workload to populate `crdb_internal.statement_statistics`, then runs `edg capture` to produce a config that approximates the observed workload.

## Setup

Start a 3-node CockroachDB cluster:

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

## Generate query statistics

Initialize the movr schema and data:

```sh
docker exec -it node1 cockroach workload init movr \
  "postgresql://root@node1:26257?sslmode=disable"
```

Run the TPC-C workload for a few minutes to build up statement statistics:

```sh
docker exec -it node1 cockroach workload run movr \
  --duration 10m \
  --concurrency 1 \
  "postgresql://root@node1:26257?sslmode=disable"
```

## Capture

Generate an edg workload config from the collected statistics:

```sh
edg capture \
  --driver pgx \
  --flavour cockroachdb \
  --url "postgres://root@localhost:26257/movr?sslmode=disable" \
  --format both \
  --min-calls 100 \
  --top 20 \
  --duration 2m \
  --workers 10 \
  -o examples/capture/captured.yaml
```

This produces two files:

- `captured.yaml` — YAML workload config
- `captured.edg` — edg-lang workload config

The generated config includes:

- **`run`** — each frequently-executed query as a run item
- **`run_weights`** — proportional to observed call counts
- **`stages`** — a single stage matching the observation window
- **`wait`** — per-query think time derived from inter-arrival times

```sh
edg capture \
  --driver pgx \
  --flavour cockroachdb \
  --url "postgres://root@localhost:26257/movr?sslmode=disable" \
  --format both \
  --min-calls 100 \
  --top 20 \
  --duration 2m \
  --workers 10 \
  -o examples/capture/captured.yaml \
  --database movr \
  --schema public
```

## Review and tune

The captured config uses `uniform(1, 10000)` as a default for all query parameters. Replace these with expressions that match your actual data distributions:

```yaml
args:
  - ref_rand('fetch_warehouses').w_id    # instead of uniform(1, 10000)
  - ref_rand('fetch_districts').d_id
```

## Teardown

```sh
docker compose -f infra/compose_crdb.yml down -v
```
