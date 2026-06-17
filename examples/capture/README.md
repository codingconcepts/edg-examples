# Capture

Generate an edg workload config from real query statistics. This example uses CockroachDB's built-in TPC-C workload to populate `crdb_internal.statement_statistics`, then runs `edg capture` to produce a config that approximates the observed workload.

### Prepare environment

Export EDG_LICENSE

```sh
export EDG_LICENSE="YOUR EDG LICENSE"
```

### CockroachDB

Start a 3-node CockroachDB cluster:

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

Run a workload:

```sh
edg all \
  --driver pgx \
  --url "postgres://root@localhost:26257?sslmode=disable" \
  --config examples/capture/inputs/crdb.edg \
  --duration 10m \
  --workers 1
```

Generate an edg workload config from the collected statistics:

```sh
edg capture \
  --driver pgx \
  --flavour cockroachdb \
  --url "postgres://root@localhost:26257/defaultdb?sslmode=disable" \
  --name examples/capture/output/crdb \
  --min-calls 100 \
  --top 20
```

This produces two files:

- `captured.yaml` - YAML workload config
- `captured.edg` - edg-lang workload config

The generated config includes:

- **`run`** - each frequently-executed query as a run item
- **`run_weights`** - proportional to observed call counts
- **`stages`** - a single stage matching the observation window
- **`wait`** - per-query think time derived from inter-arrival times

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
  -o examples/capture/crdb/captured.yaml \
  --database movr \
  --schema public
```

Review and tune

The captured config uses `uniform(1, 10000)` as a default for all query parameters. Replace these with expressions that match your actual data distributions:

```yaml
args:
  - ref_rand('fetch_warehouses').w_id    # instead of uniform(1, 10000)
  - ref_rand('fetch_districts').d_id
```

Teardown

```sh
docker compose -f infra/compose_crdb.yml down -v
```

### MySQL

Start MySQL:

```sh
docker compose -f infra/compose_mysql.yml up -d
```

Run a workload:

```sh
edg all \
  --driver mysql \
  --url "root:password@tcp(localhost:3306)/defaultdb" \
  --config examples/capture/inputs/mysql.edg \
  --duration 10m \
  --workers 1
```

Generate an edg workload config from the collected statistics:

```sh
edg capture \
  --driver mysql \
  --flavour mysql \
  --url "root:password@tcp(localhost:3306)/defaultdb" \
  --name examples/capture/output/mysql \
  --min-calls 10 \
  --top 20
```

This produces two files:

- `captured.yaml` - YAML workload config
- `captured.edg` - edg-lang workload config

The generated config includes:

- **`run`** - each frequently-executed query as a run item
- **`run_weights`** - proportional to observed call counts
- **`stages`** - a single stage matching the observation window
- **`wait`** - per-query think time derived from inter-arrival times

```sh
edg capture \
  --driver mysql \
  --flavour cockroachdb \
  --url "postgres://root@localhost:26257/movr?sslmode=disable" \
  --format both \
  --min-calls 100 \
  --top 20 \
  --duration 2m \
  --workers 10 \
  -o examples/capture/crdb/captured.yaml \
  --database movr \
  --schema public
```

Review and tune

The captured config uses `uniform(1, 10000)` as a default for all query parameters. Replace these with expressions that match your actual data distributions:

```yaml
args:
  - ref_rand('fetch_warehouses').w_id    # instead of uniform(1, 10000)
  - ref_rand('fetch_districts').d_id
```

Teardown

```sh
docker compose -f infra/compose_crdb.yml down -v
```
