# Consistency

Concurrency anomaly stress test that provokes classic database anomalies: dirty reads, non-repeatable reads, phantom reads, serialization anomalies, dirty writes, lost updates, read skew, and write skew.

Under SERIALIZABLE isolation, these manifest as transaction retry errors rather than silent data corruption. Under READ COMMITTED, some anomalies may pass through undetected.

Set `EDG_NO_ATOMIC_TX=true` to disable automatic transaction wrapping and observe anomalies more easily.

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
--config examples/consistency/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/consistency/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/consistency/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 16 \
-d 30s

edg deseed \
--driver pgx \
--config examples/consistency/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/consistency/crdb.yaml \
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
--config examples/consistency/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/consistency/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/consistency/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 16 \
-d 30s

edg deseed \
--driver mysql \
--config examples/consistency/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/consistency/mysql.yaml \
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
--config examples/consistency/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/consistency/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/consistency/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 16 \
-d 30s

edg deseed \
--driver oracle \
--config examples/consistency/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/consistency/oracle.yaml \
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
--config examples/consistency/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=consistency&encrypt=disable"

edg seed \
--driver mssql \
--config examples/consistency/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=consistency&encrypt=disable"

edg run \
--driver mssql \
--config examples/consistency/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=consistency&encrypt=disable" \
-w 16 \
-d 30s

edg deseed \
--driver mssql \
--config examples/consistency/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=consistency&encrypt=disable"

edg down \
--driver mssql \
--config examples/consistency/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=consistency&encrypt=disable"
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
--config examples/consistency/cassandra.yaml \
--url "localhost:9042"

edg seed \
--driver cassandra \
--config examples/consistency/cassandra.yaml \
--url "localhost:9042"

edg run \
--driver cassandra \
--config examples/consistency/cassandra.yaml \
--url "localhost:9042" \
-w 16 \
-d 30s

edg deseed \
--driver cassandra \
--config examples/consistency/cassandra.yaml \
--url "localhost:9042"

edg down \
--driver cassandra \
--config examples/consistency/cassandra.yaml \
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
--config examples/consistency/mongodb.yaml \
--url "mongodb://localhost:27017/consistency"

edg seed \
--driver mongodb \
--config examples/consistency/mongodb.yaml \
--url "mongodb://localhost:27017/consistency"

edg run \
--driver mongodb \
--config examples/consistency/mongodb.yaml \
--url "mongodb://localhost:27017/consistency" \
-w 16 \
-d 30s

edg deseed \
--driver mongodb \
--config examples/consistency/mongodb.yaml \
--url "mongodb://localhost:27017/consistency"

edg down \
--driver mongodb \
--config examples/consistency/mongodb.yaml \
--url "mongodb://localhost:27017/consistency"
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
--config examples/consistency/spanner.yaml \
--url "projects/test-project/instances/test-instance/databases/consistency"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg seed \
--driver spanner \
--config examples/consistency/spanner.yaml \
--url "projects/test-project/instances/test-instance/databases/consistency"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg run \
--driver spanner \
--config examples/consistency/spanner.yaml \
--url "projects/test-project/instances/test-instance/databases/consistency" \
-w 16 \
-d 30s

SPANNER_EMULATOR_HOST=localhost:9010 \
edg deseed \
--driver spanner \
--config examples/consistency/spanner.yaml \
--url "projects/test-project/instances/test-instance/databases/consistency"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg down \
--driver spanner \
--config examples/consistency/spanner.yaml \
--url "projects/test-project/instances/test-instance/databases/consistency"
```
