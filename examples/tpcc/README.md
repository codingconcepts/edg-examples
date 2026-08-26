# TPC-C

A TPC-C benchmark implementation with all 5 transaction profiles (New-Order, Payment, Order-Status, Delivery, Stock-Level) using writable CTEs for atomic execution.

## Parameters

Sizing is read from the environment, so the defaults can be overridden without editing the config:

| Variable | Default | Description |
|---|---|---|
| `WAREHOUSES` | `1` | Number of warehouses to seed |
| `DISTRICTS` | `10` | Districts per warehouse |
| `CUSTOMERS` | `30000` | Customers per district |
| `ORDERS` | `30000` | Orders per district |
| `STOCK` | `100000` | Stock rows per warehouse |
| `ITEMS` | `100000` | Number of items to seed |
| `BATCH_SIZE` | `100` | Rows per batch during seeding |
| `OL_BATCH` | `100` | Order-line rows per batch during seeding |

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
--config examples/tpcc/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/tpcc/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/tpcc/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 100 \
-d 1m

edg deseed \
--driver pgx \
--config examples/tpcc/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/tpcc/crdb.edg \
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
--config examples/tpcc/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/tpcc/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/tpcc/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 100 \
-d 1m

edg deseed \
--driver mysql \
--config examples/tpcc/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/tpcc/mysql.edg \
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
--config examples/tpcc/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/tpcc/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/tpcc/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 100 \
-d 1m

edg deseed \
--driver oracle \
--config examples/tpcc/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/tpcc/oracle.edg \
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
--config examples/tpcc/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tpcc&encrypt=disable"

edg seed \
--driver mssql \
--config examples/tpcc/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tpcc&encrypt=disable"

edg run \
--driver mssql \
--config examples/tpcc/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tpcc&encrypt=disable" \
-w 100 \
-d 1m

edg deseed \
--driver mssql \
--config examples/tpcc/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tpcc&encrypt=disable"

edg down \
--driver mssql \
--config examples/tpcc/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tpcc&encrypt=disable"
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
--config examples/tpcc/cassandra.edg \
--url "localhost:9042"

edg seed \
--driver cassandra \
--config examples/tpcc/cassandra.edg \
--url "localhost:9042"

edg run \
--driver cassandra \
--config examples/tpcc/cassandra.edg \
--url "localhost:9042" \
-w 10 \
-d 1m

edg deseed \
--driver cassandra \
--config examples/tpcc/cassandra.edg \
--url "localhost:9042"

edg down \
--driver cassandra \
--config examples/tpcc/cassandra.edg \
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
--config examples/tpcc/mongodb.edg \
--url "mongodb://localhost:27017/tpcc"

edg seed \
--driver mongodb \
--config examples/tpcc/mongodb.edg \
--url "mongodb://localhost:27017/tpcc"

edg run \
--driver mongodb \
--config examples/tpcc/mongodb.edg \
--url "mongodb://localhost:27017/tpcc" \
-w 10 \
-d 1m

edg deseed \
--driver mongodb \
--config examples/tpcc/mongodb.edg \
--url "mongodb://localhost:27017/tpcc"

edg down \
--driver mongodb \
--config examples/tpcc/mongodb.edg \
--url "mongodb://localhost:27017/tpcc"
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
--config examples/tpcc/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tpcc"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg seed \
--driver spanner \
--config examples/tpcc/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tpcc"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg run \
--driver spanner \
--config examples/tpcc/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tpcc" \
-w 10 \
-d 1m

SPANNER_EMULATOR_HOST=localhost:9010 \
edg deseed \
--driver spanner \
--config examples/tpcc/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tpcc"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg down \
--driver spanner \
--config examples/tpcc/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tpcc"
```

## SQLite

### Setup

SQLite is embedded, so there's no container to start; the database file is created on first connect.

### Run

```sh
edg up \
--driver sqlite \
--config examples/tpcc/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg seed \
--driver sqlite \
--config examples/tpcc/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg run \
--driver sqlite \
--config examples/tpcc/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate" \
-w 10 \
-d 1m

edg deseed \
--driver sqlite \
--config examples/tpcc/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg down \
--driver sqlite \
--config examples/tpcc/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"
```
