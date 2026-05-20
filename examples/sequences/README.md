# Sequences

Demonstrates all four sequence types side by side: per-worker numeric, per-worker alpha, global numeric, and global alpha.

## Functions

| Function | Scope | Description |
|---|---|---|
| `seq(start, step)` | Per worker | Auto-incrementing numeric counter |
| `seq_alpha(length)` | Per worker | Auto-incrementing alpha counter (aaa, aab, aac, ...) |
| `seq_global(name)` | Global | Shared numeric counter across all workers |
| `seq_alpha_global(name)` | Global | Shared alpha counter across all workers |

## Config

Global sequences are defined in the `seq:` section. Numeric entries use `start`/`step`, alpha entries use `length`:

```yaml
seq:
  - name: global_num_1
    start: 1
    step: 1
  - name: global_alpha_3
    length: 3
```

Alpha sequences of length N produce 26^N unique values (length 3 = 17,576; length 4 = 456,976).

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Run

```sh
edg up \
--driver pgx \
--config examples/sequences/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/sequences/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```

### Verify

Connect

```sh
cockroach sql --insecure
```

Verify

```sql
SELECT
  worker_num,
  worker_alpha,
  global_num_1,
  global_num_10,
  global_alpha_3,
  global_alpha_4
FROM sequences ORDER BY id LIMIT 20;
```

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/sequences/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/sequences/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```
