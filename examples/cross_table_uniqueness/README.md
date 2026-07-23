# Cross-table uniqueness

Demonstrates `uniq_across()` to ensure unique emails across both `users` and `admins` tables using a shared pool.

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
--config examples/cross_table_uniqueness/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
