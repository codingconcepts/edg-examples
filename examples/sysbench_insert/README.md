# Sysbench Insert

Pure insert micro-benchmark matching sysbench's `oltp_insert` profile. Every operation inserts a new row with a unique key. Useful for measuring ingestion throughput, index build cost, and storage engine write path.

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
--config examples/sysbench_insert/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/sysbench_insert/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/sysbench_insert/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 1m

edg deseed \
--driver pgx \
--config examples/sysbench_insert/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/sysbench_insert/crdb.edg \
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
--config examples/sysbench_insert/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/sysbench_insert/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/sysbench_insert/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 10 \
-d 1m

edg deseed \
--driver mysql \
--config examples/sysbench_insert/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/sysbench_insert/mysql.edg \
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
--config examples/sysbench_insert/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/sysbench_insert/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/sysbench_insert/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 10 \
-d 1m

edg deseed \
--driver oracle \
--config examples/sysbench_insert/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/sysbench_insert/oracle.edg \
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
--config examples/sysbench_insert/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=sysbench&encrypt=disable"

edg seed \
--driver mssql \
--config examples/sysbench_insert/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=sysbench&encrypt=disable"

edg run \
--driver mssql \
--config examples/sysbench_insert/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=sysbench&encrypt=disable" \
-w 10 \
-d 1m

edg deseed \
--driver mssql \
--config examples/sysbench_insert/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=sysbench&encrypt=disable"

edg down \
--driver mssql \
--config examples/sysbench_insert/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=sysbench&encrypt=disable"
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
--config examples/sysbench_insert/cassandra.edg \
--url "localhost:9042"

edg seed \
--driver cassandra \
--config examples/sysbench_insert/cassandra.edg \
--url "localhost:9042"

edg run \
--driver cassandra \
--config examples/sysbench_insert/cassandra.edg \
--url "localhost:9042" \
-w 10 \
-d 1m

edg deseed \
--driver cassandra \
--config examples/sysbench_insert/cassandra.edg \
--url "localhost:9042"

edg down \
--driver cassandra \
--config examples/sysbench_insert/cassandra.edg \
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
--config examples/sysbench_insert/mongodb.edg \
--url "mongodb://localhost:27017/sysbench"

edg seed \
--driver mongodb \
--config examples/sysbench_insert/mongodb.edg \
--url "mongodb://localhost:27017/sysbench"

edg run \
--driver mongodb \
--config examples/sysbench_insert/mongodb.edg \
--url "mongodb://localhost:27017/sysbench" \
-w 10 \
-d 1m

edg deseed \
--driver mongodb \
--config examples/sysbench_insert/mongodb.edg \
--url "mongodb://localhost:27017/sysbench"

edg down \
--driver mongodb \
--config examples/sysbench_insert/mongodb.edg \
--url "mongodb://localhost:27017/sysbench"
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
--config examples/sysbench_insert/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/sysbench"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg seed \
--driver spanner \
--config examples/sysbench_insert/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/sysbench"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg run \
--driver spanner \
--config examples/sysbench_insert/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/sysbench" \
-w 10 \
-d 1m

SPANNER_EMULATOR_HOST=localhost:9010 \
edg deseed \
--driver spanner \
--config examples/sysbench_insert/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/sysbench"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg down \
--driver spanner \
--config examples/sysbench_insert/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/sysbench"
```
