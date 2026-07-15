# environment

This minimal example shows how to reference environment variables and access them from your edg config files.

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
--config examples/environment/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

ABC="the quick brown fox" DEF="jumps over the lazy dog" \
edg seed \
--driver pgx \
--config examples/environment/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

# Check the data.
cockroach sql --insecure -e "SELECT key, val FROM e ORDER BY key"

edg deseed \
--driver pgx \
--config examples/environment/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/environment/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
