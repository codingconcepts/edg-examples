# CH-benCHmark

Mixed OLTP+OLAP workload combining TPC-C transactions with TPC-H-style analytical queries running concurrently on the same schema. Tests HTAP (Hybrid Transactional/Analytical Processing) capability.

Uses the full TPC-C schema with nation, region, and supplier tables added per the CH-benCHmark specification.

Workload mix:

- **OLTP (80%)** - TPC-C transactions (new_order, payment, order_status, delivery, stock_level)
- **OLAP (20%)** - Analytical queries adapted to TPC-C schema (pricing summary, revenue forecast, important stock, shipping modes)

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
--config examples/ch_benchmark/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/ch_benchmark/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/ch_benchmark/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 1m

edg deseed \
--driver pgx \
--config examples/ch_benchmark/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/ch_benchmark/crdb.yaml \
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
--config examples/ch_benchmark/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/ch_benchmark/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/ch_benchmark/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 10 \
-d 1m

edg deseed \
--driver mysql \
--config examples/ch_benchmark/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/ch_benchmark/mysql.yaml \
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
--config examples/ch_benchmark/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/ch_benchmark/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/ch_benchmark/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 10 \
-d 1m

edg deseed \
--driver oracle \
--config examples/ch_benchmark/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/ch_benchmark/oracle.yaml \
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
--config examples/ch_benchmark/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ch&encrypt=disable"

edg seed \
--driver mssql \
--config examples/ch_benchmark/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ch&encrypt=disable"

edg run \
--driver mssql \
--config examples/ch_benchmark/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ch&encrypt=disable" \
-w 10 \
-d 1m

edg deseed \
--driver mssql \
--config examples/ch_benchmark/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ch&encrypt=disable"

edg down \
--driver mssql \
--config examples/ch_benchmark/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ch&encrypt=disable"
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
--config examples/ch_benchmark/cassandra.yaml \
--url "localhost:9042"

edg seed \
--driver cassandra \
--config examples/ch_benchmark/cassandra.yaml \
--url "localhost:9042"

edg run \
--driver cassandra \
--config examples/ch_benchmark/cassandra.yaml \
--url "localhost:9042" \
-w 10 \
-d 1m

edg deseed \
--driver cassandra \
--config examples/ch_benchmark/cassandra.yaml \
--url "localhost:9042"

edg down \
--driver cassandra \
--config examples/ch_benchmark/cassandra.yaml \
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
--config examples/ch_benchmark/mongodb.yaml \
--url "mongodb://localhost:27017/ch"

edg seed \
--driver mongodb \
--config examples/ch_benchmark/mongodb.yaml \
--url "mongodb://localhost:27017/ch"

edg run \
--driver mongodb \
--config examples/ch_benchmark/mongodb.yaml \
--url "mongodb://localhost:27017/ch" \
-w 10 \
-d 1m

edg deseed \
--driver mongodb \
--config examples/ch_benchmark/mongodb.yaml \
--url "mongodb://localhost:27017/ch"

edg down \
--driver mongodb \
--config examples/ch_benchmark/mongodb.yaml \
--url "mongodb://localhost:27017/ch"
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
--config examples/ch_benchmark/spanner.yaml \
--url "projects/test-project/instances/test-instance/databases/ch"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg seed \
--driver spanner \
--config examples/ch_benchmark/spanner.yaml \
--url "projects/test-project/instances/test-instance/databases/ch"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg run \
--driver spanner \
--config examples/ch_benchmark/spanner.yaml \
--url "projects/test-project/instances/test-instance/databases/ch" \
-w 10 \
-d 1m

SPANNER_EMULATOR_HOST=localhost:9010 \
edg deseed \
--driver spanner \
--config examples/ch_benchmark/spanner.yaml \
--url "projects/test-project/instances/test-instance/databases/ch"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg down \
--driver spanner \
--config examples/ch_benchmark/spanner.yaml \
--url "projects/test-project/instances/test-instance/databases/ch"
```
