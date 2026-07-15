# Minimal

This is a minimal config design to build familiarity with edg.

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
--config examples/minimal/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 1 \
-d 10s
```