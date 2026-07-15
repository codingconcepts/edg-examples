# each_cartesian

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
--config examples/each_cartesian/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/each_cartesian/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

# Check the data.
cockroach sql --insecure -e "SELECT COUNT(*) FROM c"

edg deseed \
--driver pgx \
--config examples/each_cartesian/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/each_cartesian/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
