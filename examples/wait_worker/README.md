# Wait Worker

An example of a delayed one-shot worker that applies a schema change mid-run.

The workload queries customers by email against an unindexed column (full table scan). After 30 seconds, a `delay` worker fires once to create an index, and query latency drops immediately.

```yaml
workers:
  - name: add_email_index
    delay: 30s
    type: exec
    query: CREATE INDEX IF NOT EXISTS idx_customer_email ON customer (email)
```

The `delay` field differs from `rate`: a `rate` worker runs repeatedly on a schedule (e.g. `1/5s`), while a `delay` worker waits for the specified duration, executes once, then exits.

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
--config examples/wait_worker/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 90s \
--metrics-samples 500 \
--tui
```

### What to observe

For the first ~30 seconds, `lookup_by_email` performs a full table scan across 100k rows. After the index is created, the same query uses an index lookup and latency drops sharply.
