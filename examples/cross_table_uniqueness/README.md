# Cross-table uniqueness

Demonstrates `uniq_across()` to ensure unique emails across both `users` and `admins` tables using a shared pool, alongside plain `uniq()` for comparison.

## Which one to reach for

`uniq()`'s seen set covers one pass of argument generation and resets before the next. A batch query generates all of its rows in one pass, so `populate_codes` - a single batch of 50 - is guaranteed 50 distinct codes. Split it across two batches and the second would start from an empty set.

`uniq_across()` keeps a named pool for the lifetime of the environment. That is what lets `populate_users` and `populate_admins` share the `emails` pool and never collide, even though they are separate queries. In a non-batch `run` query it is the only form that de-duplicates across iterations, because every iteration is its own pass.

## Quoted and unquoted

`populate_codes` passes `uniq(regex('[A-Z]{4}'))` unquoted while the email queries pass `"gen('email')"` quoted. Both redraw: a plain call would normally be evaluated before `uniq()` ever saw it, so the compiler quotes call-shaped arguments for you. Quoting explicitly is the clearer spelling, and the one to prefer in new configs.

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
