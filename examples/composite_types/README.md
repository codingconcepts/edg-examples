# Composite Types

Demonstrates CockroachDB composite types (user-defined record types) used as column types. Creates `amount` and `dimensions` composite types, then uses them in product and order tables.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

```sh
edg all \
--driver pgx \
--config examples/composite_types/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 10s

# Or separately.
edg up \
--driver pgx \
--config examples/composite_types/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/composite_types/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/composite_types/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 1m

edg deseed \
--driver pgx \
--config examples/composite_types/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/composite_types/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```
