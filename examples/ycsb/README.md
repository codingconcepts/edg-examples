# YCSB

A Yahoo! Cloud Serving Benchmark implementation with all 6 workload profiles (A-F) using Zipfian key distribution. Switch between profiles by changing `run_weights` in the config.

Workload profiles:

- **A** - Update heavy: 50% read, 50% update
- **B** - Read mostly: 95% read, 5% update
- **C** - Read only: 100% read
- **D** - Read latest: 95% read, 5% insert
- **E** - Short ranges: 95% scan, 5% insert
- **F** - Read-modify-write: 50% read, 50% read-modify-write

## Parameters

Sizing is read from the environment, so the defaults can be overridden without editing the config:

| Variable | Default | Description |
|---|---|---|
| `RECORDS` | `1000` | Number of rows to seed into `usertable` |
| `BATCH_SIZE` | `100` | Rows per batch during seeding |
| `ZIPF_S` | `1.2` | Zipfian skew - higher values concentrate access on fewer keys |

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
--config examples/ycsb/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/ycsb/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/ycsb/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 100 \
-d 1m

edg deseed \
--driver pgx \
--config examples/ycsb/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/ycsb/crdb.edg \
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
--config examples/ycsb/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/ycsb/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/ycsb/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 100 \
-d 1m

edg deseed \
--driver mysql \
--config examples/ycsb/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/ycsb/mysql.edg \
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
--config examples/ycsb/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/ycsb/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/ycsb/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 100 \
-d 1m

edg deseed \
--driver oracle \
--config examples/ycsb/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/ycsb/oracle.edg \
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
--config examples/ycsb/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ycsb&encrypt=disable"

edg seed \
--driver mssql \
--config examples/ycsb/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ycsb&encrypt=disable"

edg run \
--driver mssql \
--config examples/ycsb/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ycsb&encrypt=disable" \
-w 100 \
-d 1m

edg deseed \
--driver mssql \
--config examples/ycsb/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ycsb&encrypt=disable"

edg down \
--driver mssql \
--config examples/ycsb/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ycsb&encrypt=disable"
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
--config examples/ycsb/cassandra.edg \
--url "localhost:9042"

edg seed \
--driver cassandra \
--config examples/ycsb/cassandra.edg \
--url "localhost:9042"

edg run \
--driver cassandra \
--config examples/ycsb/cassandra.edg \
--url "localhost:9042" \
-w 10 \
-d 1m

edg deseed \
--driver cassandra \
--config examples/ycsb/cassandra.edg \
--url "localhost:9042"

edg down \
--driver cassandra \
--config examples/ycsb/cassandra.edg \
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
--config examples/ycsb/mongodb.edg \
--url "mongodb://localhost:27017/ycsb"

edg seed \
--driver mongodb \
--config examples/ycsb/mongodb.edg \
--url "mongodb://localhost:27017/ycsb"

edg run \
--driver mongodb \
--config examples/ycsb/mongodb.edg \
--url "mongodb://localhost:27017/ycsb" \
-w 10 \
-d 1m

edg deseed \
--driver mongodb \
--config examples/ycsb/mongodb.edg \
--url "mongodb://localhost:27017/ycsb"

edg down \
--driver mongodb \
--config examples/ycsb/mongodb.edg \
--url "mongodb://localhost:27017/ycsb"
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
--config examples/ycsb/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/ycsb"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg seed \
--driver spanner \
--config examples/ycsb/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/ycsb"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg run \
--driver spanner \
--config examples/ycsb/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/ycsb" \
-w 10 \
-d 1m

SPANNER_EMULATOR_HOST=localhost:9010 \
edg deseed \
--driver spanner \
--config examples/ycsb/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/ycsb"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg down \
--driver spanner \
--config examples/ycsb/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/ycsb"
```

## SQLite

### Setup

SQLite is embedded, so there's no container to start; the database file is created on first connect.

### Run

```sh
edg up \
--driver sqlite \
--config examples/ycsb/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg seed \
--driver sqlite \
--config examples/ycsb/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg run \
--driver sqlite \
--config examples/ycsb/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate" \
-w 10 \
-d 1m

edg deseed \
--driver sqlite \
--config examples/ycsb/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg down \
--driver sqlite \
--config examples/ycsb/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"
```

## Redis

### Setup

```sh
docker compose -f infra/compose_redis.yml up -d
```

### Run

```sh
edg up \
--driver redis \
--config examples/ycsb/redis.edg \
--url "redis://localhost:6379"

edg seed \
--driver redis \
--config examples/ycsb/redis.edg \
--url "redis://localhost:6379"

edg run \
--driver redis \
--config examples/ycsb/redis.edg \
--url "redis://localhost:6379" \
-w 10 \
-d 1m

edg deseed \
--driver redis \
--config examples/ycsb/redis.edg \
--url "redis://localhost:6379"

edg down \
--driver redis \
--config examples/ycsb/redis.edg \
--url "redis://localhost:6379"
```
