# SEATS

Airline reservation system benchmark. Models flights, customers, and seat reservations with contention on seat availability. Transactions include finding flights, checking open seats, booking, updating, and cancelling reservations.

## Parameters

Sizing is read from the environment, so the defaults can be overridden without editing the config:

| Variable | Default | Description |
|---|---|---|
| `COUNTRIES` | `50` | Number of countries to seed |
| `AIRPORTS` | `200` | Number of airports to seed |
| `AIRLINES` | `20` | Number of airlines to seed |
| `CUSTOMERS` | `1000` | Number of customers to seed |
| `FLIGHTS` | `500` | Number of flights to seed |
| `SEATS_PER_FLIGHT` | `150` | Seats on each flight |
| `RESERVATIONS_PER_FLIGHT` | `120` | Reservations booked per flight during seeding |
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
--config examples/seats/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/seats/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/seats/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 1m

edg deseed \
--driver pgx \
--config examples/seats/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/seats/crdb.edg \
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
--config examples/seats/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/seats/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/seats/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 10 \
-d 1m

edg deseed \
--driver mysql \
--config examples/seats/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/seats/mysql.edg \
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
--config examples/seats/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/seats/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/seats/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 10 \
-d 1m

edg deseed \
--driver oracle \
--config examples/seats/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/seats/oracle.edg \
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
--config examples/seats/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=seats&encrypt=disable"

edg seed \
--driver mssql \
--config examples/seats/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=seats&encrypt=disable"

edg run \
--driver mssql \
--config examples/seats/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=seats&encrypt=disable" \
-w 10 \
-d 1m

edg deseed \
--driver mssql \
--config examples/seats/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=seats&encrypt=disable"

edg down \
--driver mssql \
--config examples/seats/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=seats&encrypt=disable"
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
--config examples/seats/cassandra.edg \
--url "localhost:9042"

edg seed \
--driver cassandra \
--config examples/seats/cassandra.edg \
--url "localhost:9042"

edg run \
--driver cassandra \
--config examples/seats/cassandra.edg \
--url "localhost:9042" \
-w 10 \
-d 1m

edg deseed \
--driver cassandra \
--config examples/seats/cassandra.edg \
--url "localhost:9042"

edg down \
--driver cassandra \
--config examples/seats/cassandra.edg \
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
--config examples/seats/mongodb.edg \
--url "mongodb://localhost:27017/seats"

edg seed \
--driver mongodb \
--config examples/seats/mongodb.edg \
--url "mongodb://localhost:27017/seats"

edg run \
--driver mongodb \
--config examples/seats/mongodb.edg \
--url "mongodb://localhost:27017/seats" \
-w 10 \
-d 1m

edg deseed \
--driver mongodb \
--config examples/seats/mongodb.edg \
--url "mongodb://localhost:27017/seats"

edg down \
--driver mongodb \
--config examples/seats/mongodb.edg \
--url "mongodb://localhost:27017/seats"
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
--config examples/seats/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/seats"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg seed \
--driver spanner \
--config examples/seats/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/seats"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg run \
--driver spanner \
--config examples/seats/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/seats" \
-w 10 \
-d 1m

SPANNER_EMULATOR_HOST=localhost:9010 \
edg deseed \
--driver spanner \
--config examples/seats/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/seats"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg down \
--driver spanner \
--config examples/seats/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/seats"
```

## SQLite

### Setup

SQLite is embedded, so there's no container to start; the database file is created on first connect.

### Run

```sh
edg up \
--driver sqlite \
--config examples/seats/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg seed \
--driver sqlite \
--config examples/seats/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg run \
--driver sqlite \
--config examples/seats/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate" \
-w 10 \
-d 1m

edg deseed \
--driver sqlite \
--config examples/seats/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg down \
--driver sqlite \
--config examples/seats/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"
```
