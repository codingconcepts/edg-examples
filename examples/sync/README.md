# Sync

Write identical data to multiple databases and verify consistency. Tests dual-write across SQL and NoSQL engines.

## CockroachDB + MySQL

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
docker compose -f infra/compose_mysql.yml up -d

until cockroach sql --insecure -e "SELECT 1" &>/dev/null; do sleep 1; done
until mysql -u root -ppassword -h 127.0.0.1 -e "SELECT 1" &>/dev/null 2>&1; do sleep 1; done
```

### Dual-write

Seed both databases with the same data (deterministic via `--rng-seed`), then verify:

```sh
edg sync run \
--source-driver mysql \
--source-url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
--source-config examples/sync/mysql.edg \
--target-driver pgx \
--target-url "postgres://root:password@localhost:26257/defaultdb?sslmode=disable" \
--target-config examples/sync/crdb.edg \
--rng-seed 42
```

Check data in both databases:

```sh
cockroach sql --insecure -e "SELECT id, name FROM users ORDER BY id LIMIT 5"
mysql -u root -ppassword -h 127.0.0.1 defaultdb -e "SELECT id, name FROM users ORDER BY id LIMIT 5"

cockroach sql --insecure -e "SELECT * FROM orders LIMIT 5"
mysql -u root -ppassword -h 127.0.0.1 defaultdb -e "SELECT * FROM orders LIMIT 5"
```

```sh
edg sync verify \
--source-driver mysql \
--source-url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
--target-driver pgx \
--target-url "postgres://root:password@localhost:26257/defaultdb?sslmode=disable" \
--tables users,orders \
--order-by id \
--ignore-columns created_at
```

### Replication (MOLT Fetch)

Seed the source only. Create schema on the target manually, then use an external tool like [MOLT Fetch](https://www.cockroachlabs.com/docs/molt/molt-fetch) to copy data across.

Create schema on both, seed source only:

```sh
edg up \
--driver mysql \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
--config examples/sync/mysql.edg

edg up \
--driver pgx \
--url "postgres://root:password@localhost:26257/defaultdb?sslmode=disable" \
--config examples/sync/crdb.edg

edg sync run \
--source-driver mysql \
--source-url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
--source-config examples/sync/mysql.edg \
--rng-seed 42
```

Copy data with MOLT Fetch (or similar):

```sh
molt fetch \
--source "root:password@tcp(localhost:3306)/defaultdb" \
--target "postgres://root:password@localhost:26257/defaultdb?sslmode=disable"
```

Verify:

```sh
edg sync verify \
--source-driver mysql \
--source-url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
--target-driver pgx \
--target-url "postgres://root:password@localhost:26257/defaultdb?sslmode=disable" \
--tables users,orders \
--order-by id \
--ignore-columns created_at \
--wait 5s
```

### Teardown

```sh
edg sync down \
--source-driver mysql \
--source-url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
--source-config examples/sync/mysql.edg \
--target-driver pgx \
--target-url "postgres://root:password@localhost:26257/defaultdb?sslmode=disable" \
--target-config examples/sync/crdb.edg

docker compose -f infra/compose_crdb.yml down
docker compose -f infra/compose_mysql.yml down
```

## CockroachDB + MongoDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
docker compose -f infra/compose_mongo.yml up -d

until cockroach sql --insecure -e "SELECT 1" &>/dev/null; do sleep 1; done
until mongosh --quiet --eval "rs.initiate()" &>/dev/null; do sleep 1; done
```

### Dual-write and verify

```sh
edg sync run \
--source-driver mongodb \
--source-url "mongodb://localhost:27017/edg?directConnection=true" \
--source-config examples/sync/mongodb.edg \
--target-driver pgx \
--target-url "postgres://root:password@localhost:26257/defaultdb?sslmode=disable" \
--target-config examples/sync/crdb.edg \
--rng-seed 42
```

Columns unique to one side (`created_at` in CockroachDB, `_id` in MongoDB) are automatically excluded from comparison:

```sh
edg sync verify \
--source-driver mongodb \
--source-url "mongodb://localhost:27017/edg?directConnection=true" \
--target-driver pgx \
--target-url "postgres://root:password@localhost:26257/defaultdb?sslmode=disable" \
--tables users,orders \
--order-by id
```

### Teardown

```sh
edg sync down \
--source-driver mongodb \
--source-url "mongodb://localhost:27017/edg?directConnection=true" \
--source-config examples/sync/mongodb.edg \
--target-driver pgx \
--target-url "postgres://root:password@localhost:26257/defaultdb?sslmode=disable" \
--target-config examples/sync/crdb.edg

docker compose -f infra/compose_crdb.yml down
docker compose -f infra/compose_mongo.yml down
```

## CockroachDB + Cassandra

Cassandra rows are fetched using server-side paging (`PageSize`) and sorted client-side by `--order-by` to match SQL ordering.

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
docker compose -f infra/compose_cassandra.yml up -d

until cockroach sql --insecure -e "SELECT 1" &>/dev/null; do sleep 1; done
until cqlsh -e "DESCRIBE CLUSTER" &>/dev/null; do sleep 2; done
```

### Dual-write and verify

```sh
edg sync run \
--source-driver cassandra \
--source-url "cassandra://127.0.0.1:9042" \
--source-config examples/sync/cassandra.edg \
--target-driver pgx \
--target-url "postgres://root:password@localhost:26257/defaultdb?sslmode=disable" \
--target-config examples/sync/crdb.edg \
--rng-seed 42
```

```sh
edg sync verify \
--source-driver cassandra \
--source-url "cassandra://127.0.0.1:9042/edg" \
--target-driver pgx \
--target-url "postgres://root:password@localhost:26257/defaultdb?sslmode=disable" \
--tables users,orders \
--order-by id
```

### Teardown

```sh
edg sync down \
--source-driver cassandra \
--source-url "cassandra://127.0.0.1:9042" \
--source-config examples/sync/cassandra.edg \
--target-driver pgx \
--target-url "postgres://root:password@localhost:26257/defaultdb?sslmode=disable" \
--target-config examples/sync/crdb.edg

docker compose -f infra/compose_crdb.yml down
docker compose -f infra/compose_cassandra.yml down
```
