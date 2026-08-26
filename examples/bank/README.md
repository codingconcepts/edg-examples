# Bank

A simpler workload modelling bank account operations (balance checks, credits, transfers). Useful for contention and correctness testing.

## Parameters

Sizing is read from the environment, so the defaults can be overridden without editing the config:

| Variable | Default | Description |
|---|---|---|
| `CUSTOMERS` | `1000` | Number of customers (and accounts) to seed |
| `INITIAL_BALANCE` | `1000` | Starting balance on every account |
| `BATCH_SIZE` | `100` | Rows per batch during seeding |

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
--config examples/bank/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

# Or separately.
edg up \
--driver pgx \
--config examples/bank/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/bank/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/bank/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 10m

edg deseed \
--driver pgx \
--config examples/bank/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/bank/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```

## MySQL

### Setup

```sh
docker compose -f infra/compose_mysql.yml up -d
```

### Run

```sh
edg all \
--driver mysql \
--config examples/bank/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"
```

## Oracle

### Setup

```sh
docker compose -f infra/compose_oracle.yml up -d
```

### Run

```sh
edg all \
--driver oracle \
--config examples/bank/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"
```

## MSSQL

### Setup

```sh
docker compose -f infra/compose_mssql.yml up -d
```

### Run

```sh
edg all \
--driver mssql \
--config examples/bank/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=bank&encrypt=disable"

# Or separately.
edg up \
--driver mssql \
--config examples/bank/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=bank&encrypt=disable"

edg seed \
--driver mssql \
--config examples/bank/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=bank&encrypt=disable"

edg run \
--driver mssql \
--config examples/bank/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=bank&encrypt=disable" \
-w 100 \
-d 1m

edg deseed \
--driver mssql \
--config examples/bank/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=bank&encrypt=disable"

edg down \
--driver mssql \
--config examples/bank/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=bank&encrypt=disable"
```

## Cassandra

### Setup

```sh
docker compose -f infra/compose_cassandra.yml up -d
```

### Run

```sh
edg all \
--driver cassandra \
--config examples/bank/cassandra.edg \
--url "localhost:9042"

# Or separately.
edg up \
--driver cassandra \
--config examples/bank/cassandra.edg \
--url "localhost:9042"

edg seed \
--driver cassandra \
--config examples/bank/cassandra.edg \
--url "localhost:9042"

edg run \
--driver cassandra \
--config examples/bank/cassandra.edg \
--url "localhost:9042" \
-w 10 \
-d 1m

edg deseed \
--driver cassandra \
--config examples/bank/cassandra.edg \
--url "localhost:9042"

edg down \
--driver cassandra \
--config examples/bank/cassandra.edg \
--url "localhost:9042"
```

## MongoDB

### Setup

```sh
docker compose -f infra/compose_mongo.yml up -d
```

### Run

```sh
edg all \
--driver mongodb \
--config examples/bank/mongodb.edg \
--url "mongodb://localhost:27017/bank"

# Or separately.
edg up \
--driver mongodb \
--config examples/bank/mongodb.edg \
--url "mongodb://localhost:27017/bank"

edg seed \
--driver mongodb \
--config examples/bank/mongodb.edg \
--url "mongodb://localhost:27017/bank"

edg run \
--driver mongodb \
--config examples/bank/mongodb.edg \
--url "mongodb://localhost:27017/bank" \
-w 10 \
-d 1m

edg deseed \
--driver mongodb \
--config examples/bank/mongodb.edg \
--url "mongodb://localhost:27017/bank"

edg down \
--driver mongodb \
--config examples/bank/mongodb.edg \
--url "mongodb://localhost:27017/bank"
```

## Cloud Spanner

### Setup

```sh
docker compose -f infra/compose_spanner.yml up -d
```

### Run

```sh
SPANNER_EMULATOR_HOST=localhost:9010 \
edg all \
--driver spanner \
--config examples/bank/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/bank"

# Or separately.
SPANNER_EMULATOR_HOST=localhost:9010 \
edg up \
--driver spanner \
--config examples/bank/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/bank"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg seed \
--driver spanner \
--config examples/bank/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/bank"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg run \
--driver spanner \
--config examples/bank/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/bank" \
-w 10 \
-d 1m

SPANNER_EMULATOR_HOST=localhost:9010 \
edg deseed \
--driver spanner \
--config examples/bank/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/bank"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg down \
--driver spanner \
--config examples/bank/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/bank"
```

## SQLite

### Setup

SQLite is embedded, so there's no container to start; the database file is created on first connect.

### Run

```sh
edg all \
--driver sqlite \
--config examples/bank/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

# Or separately.
edg up \
--driver sqlite \
--config examples/bank/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg seed \
--driver sqlite \
--config examples/bank/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg run \
--driver sqlite \
--config examples/bank/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate" \
-w 10 \
-d 1m

edg deseed \
--driver sqlite \
--config examples/bank/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg down \
--driver sqlite \
--config examples/bank/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"
```
