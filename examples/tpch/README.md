# TPC-H

The TPC-H decision-support schema - `region`, `nation`, `supplier`, `part`, `partsupp`, `customer`, `orders`, and `lineitem` - with four of the query set as the run loop. Analytical rather than transactional: few, heavy queries over the whole dataset.

Run queries:

- **q1_pricing_summary** (25%) - Pricing summary report, aggregating `lineitem` by return flag and line status
- **q3_shipping_priority** (25%) - Unshipped orders with the highest revenue
- **q6_forecasting_revenue** (25%) - Revenue change from eliminating discounts in a date range
- **q14_promotion_effect** (25%) - Share of revenue from promotional parts

## Parameters

Sizing is read from the environment, so the defaults can be overridden without editing the config:

| Variable | Default | Description |
|---|---|---|
| `SCALE_FACTOR` | `1` | Multiplier applied to the seeded row counts |
| `REGIONS` | `5` | Number of regions to seed |
| `NATIONS` | `25` | Number of nations to seed |
| `SUPPLIERS` | `100` | Number of suppliers to seed |
| `PARTS` | `200` | Number of parts to seed |
| `CUSTOMERS` | `150` | Number of customers to seed |
| `ORDERS` | `1000` | Number of orders to seed |
| `BATCH_SIZE` | `100` | Rows per batch during seeding |

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
--config examples/tpch/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/tpch/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/tpch/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 1m

edg deseed \
--driver pgx \
--config examples/tpch/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/tpch/crdb.edg \
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
--config examples/tpch/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/tpch/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/tpch/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 10 \
-d 1m

edg deseed \
--driver mysql \
--config examples/tpch/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/tpch/mysql.edg \
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
--config examples/tpch/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/tpch/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/tpch/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 10 \
-d 1m

edg deseed \
--driver oracle \
--config examples/tpch/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/tpch/oracle.edg \
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
--config examples/tpch/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tpch&encrypt=disable"

edg seed \
--driver mssql \
--config examples/tpch/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tpch&encrypt=disable"

edg run \
--driver mssql \
--config examples/tpch/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tpch&encrypt=disable" \
-w 10 \
-d 1m

edg deseed \
--driver mssql \
--config examples/tpch/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tpch&encrypt=disable"

edg down \
--driver mssql \
--config examples/tpch/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tpch&encrypt=disable"
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
--config examples/tpch/cassandra.edg \
--url "localhost:9042"

edg seed \
--driver cassandra \
--config examples/tpch/cassandra.edg \
--url "localhost:9042"

edg run \
--driver cassandra \
--config examples/tpch/cassandra.edg \
--url "localhost:9042" \
-w 10 \
-d 1m

edg deseed \
--driver cassandra \
--config examples/tpch/cassandra.edg \
--url "localhost:9042"

edg down \
--driver cassandra \
--config examples/tpch/cassandra.edg \
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
--config examples/tpch/mongodb.edg \
--url "mongodb://localhost:27017/tpch"

edg seed \
--driver mongodb \
--config examples/tpch/mongodb.edg \
--url "mongodb://localhost:27017/tpch"

edg run \
--driver mongodb \
--config examples/tpch/mongodb.edg \
--url "mongodb://localhost:27017/tpch" \
-w 10 \
-d 1m

edg deseed \
--driver mongodb \
--config examples/tpch/mongodb.edg \
--url "mongodb://localhost:27017/tpch"

edg down \
--driver mongodb \
--config examples/tpch/mongodb.edg \
--url "mongodb://localhost:27017/tpch"
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
--config examples/tpch/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tpch"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg seed \
--driver spanner \
--config examples/tpch/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tpch"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg run \
--driver spanner \
--config examples/tpch/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tpch" \
-w 10 \
-d 1m

SPANNER_EMULATOR_HOST=localhost:9010 \
edg deseed \
--driver spanner \
--config examples/tpch/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tpch"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg down \
--driver spanner \
--config examples/tpch/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tpch"
```

## SQLite

### Setup

SQLite is embedded, so there's no container to start; the database file is created on first connect.

### Run

```sh
edg up \
--driver sqlite \
--config examples/tpch/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg seed \
--driver sqlite \
--config examples/tpch/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg run \
--driver sqlite \
--config examples/tpch/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate" \
-w 10 \
-d 1m

edg deseed \
--driver sqlite \
--config examples/tpch/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg down \
--driver sqlite \
--config examples/tpch/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"
```
