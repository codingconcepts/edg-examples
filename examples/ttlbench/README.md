# TTL Bench

An insert-heavy workload against a table whose rows expire after 30 minutes, to measure what row expiry costs while ingest is running. There's no seed phase; the table fills from the run loop.

Run queries:

- **insert_row** (80%, 70% where expiry is manual) - Insert a row with a random payload
- **read_recent** (20%) - Read the last five minutes of rows
- **delete_expired** / **cleanup_expired** (10%, manual-expiry dialects only) - Delete a batch of expired rows

How expiry happens depends on the database:

| Database | Mechanism |
|---|---|
| CockroachDB | Row-level TTL (`ttl_expire_after = '30 minutes'`, per-minute TTL job) |
| Cassandra | `USING TTL 1800` on insert |
| MongoDB | TTL index with `expireAfterSeconds: 1800` |
| MySQL, Oracle, MSSQL, SQLite, Spanner | No native row expiry, so the workload deletes expired rows itself |

## Parameters

Sizing is read from the environment, so the defaults can be overridden without editing the config:

| Variable | Default | Description |
|---|---|---|
| `PAYLOAD_SIZE` | `256` | Payload size in bytes |

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
--config examples/ttlbench/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/ttlbench/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 1m

edg deseed \
--driver pgx \
--config examples/ttlbench/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/ttlbench/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```

## MySQL

### Setup

```sh
docker compose -f infra/compose_mysql.yml up -d
```

### Run

```sh
edg up \
--driver mysql \
--config examples/ttlbench/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/ttlbench/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 10 \
-d 1m

edg deseed \
--driver mysql \
--config examples/ttlbench/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/ttlbench/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"
```

## Oracle

### Setup

```sh
docker compose -f infra/compose_oracle.yml up -d
```

### Run

```sh
edg up \
--driver oracle \
--config examples/ttlbench/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/ttlbench/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 10 \
-d 1m

edg deseed \
--driver oracle \
--config examples/ttlbench/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/ttlbench/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"
```

## MSSQL

### Setup

```sh
docker compose -f infra/compose_mssql.yml up -d
```

### Run

```sh
edg up \
--driver mssql \
--config examples/ttlbench/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ttlbench&encrypt=disable"

edg run \
--driver mssql \
--config examples/ttlbench/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ttlbench&encrypt=disable" \
-w 10 \
-d 1m

edg deseed \
--driver mssql \
--config examples/ttlbench/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ttlbench&encrypt=disable"

edg down \
--driver mssql \
--config examples/ttlbench/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ttlbench&encrypt=disable"
```

## Cassandra

### Setup

```sh
docker compose -f infra/compose_cassandra.yml up -d
```

### Run

```sh
edg up \
--driver cassandra \
--config examples/ttlbench/cassandra.edg \
--url "localhost:9042"

edg run \
--driver cassandra \
--config examples/ttlbench/cassandra.edg \
--url "localhost:9042" \
-w 10 \
-d 1m

edg deseed \
--driver cassandra \
--config examples/ttlbench/cassandra.edg \
--url "localhost:9042"

edg down \
--driver cassandra \
--config examples/ttlbench/cassandra.edg \
--url "localhost:9042"
```

## MongoDB

### Setup

```sh
docker compose -f infra/compose_mongo.yml up -d
```

### Run

```sh
edg up \
--driver mongodb \
--config examples/ttlbench/mongodb.edg \
--url "mongodb://localhost:27017/ttlbench"

edg run \
--driver mongodb \
--config examples/ttlbench/mongodb.edg \
--url "mongodb://localhost:27017/ttlbench" \
-w 10 \
-d 1m

edg deseed \
--driver mongodb \
--config examples/ttlbench/mongodb.edg \
--url "mongodb://localhost:27017/ttlbench"

edg down \
--driver mongodb \
--config examples/ttlbench/mongodb.edg \
--url "mongodb://localhost:27017/ttlbench"
```

## Cloud Spanner

### Setup

```sh
docker compose -f infra/compose_spanner.yml up -d
```

### Run

```sh
SPANNER_EMULATOR_HOST=localhost:9010 \
edg up \
--driver spanner \
--config examples/ttlbench/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/ttlbench"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg run \
--driver spanner \
--config examples/ttlbench/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/ttlbench" \
-w 10 \
-d 1m

SPANNER_EMULATOR_HOST=localhost:9010 \
edg deseed \
--driver spanner \
--config examples/ttlbench/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/ttlbench"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg down \
--driver spanner \
--config examples/ttlbench/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/ttlbench"
```

## SQLite

### Setup

SQLite is embedded, so there's no container to start; the database file is created on first connect.

### Run

```sh
edg up \
--driver sqlite \
--config examples/ttlbench/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg run \
--driver sqlite \
--config examples/ttlbench/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate" \
-w 10 \
-d 1m

edg deseed \
--driver sqlite \
--config examples/ttlbench/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg down \
--driver sqlite \
--config examples/ttlbench/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"
```
