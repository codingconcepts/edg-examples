# Minimal

This is a minimal config design to build familiarity with edg.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

```sh
go run ./cmd/edg all \
--driver pgx \
--config _examples/minimal/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 1 \
-d 10s
```