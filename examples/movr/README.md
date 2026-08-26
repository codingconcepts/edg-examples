# MovR

CockroachDB's MovR vehicle-sharing schema: `users`, `vehicles`, `rides`, `vehicle_location_histories`, `promo_codes`, and `user_promo_codes`, all keyed by city to model a geo-partitioned fleet.

Run queries:

- **create_ride** (20%) - Insert a ride joining a rider to a vehicle
- **read_rides** (20%) - A rider's recent rides in their city
- **read_vehicles** (20%) - Available vehicles in a city
- **add_vehicle_location** (15%) - Append a location ping to an in-flight ride
- **update_ride** (15%) - Complete a ride, setting end address, time, and revenue
- **apply_promo_code** (10%) - Attach a promo code to a user

## Parameters

Sizing is read from the environment, so the defaults can be overridden without editing the config:

| Variable | Default | Description |
|---|---|---|
| `NUM_USERS` | `100` | Number of users to seed |
| `NUM_VEHICLES` | `50` | Number of vehicles to seed |
| `NUM_RIDES` | `200` | Number of historic rides to seed |
| `NUM_PROMO_CODES` | `10` | Number of promo codes to seed |
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
--config examples/movr/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/movr/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/movr/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 1m

edg deseed \
--driver pgx \
--config examples/movr/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/movr/crdb.edg \
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
--config examples/movr/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/movr/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/movr/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 10 \
-d 1m

edg deseed \
--driver mysql \
--config examples/movr/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/movr/mysql.edg \
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
--config examples/movr/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/movr/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/movr/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 10 \
-d 1m

edg deseed \
--driver oracle \
--config examples/movr/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/movr/oracle.edg \
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
--config examples/movr/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=movr&encrypt=disable"

edg seed \
--driver mssql \
--config examples/movr/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=movr&encrypt=disable"

edg run \
--driver mssql \
--config examples/movr/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=movr&encrypt=disable" \
-w 10 \
-d 1m

edg deseed \
--driver mssql \
--config examples/movr/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=movr&encrypt=disable"

edg down \
--driver mssql \
--config examples/movr/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=movr&encrypt=disable"
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
--config examples/movr/cassandra.edg \
--url "localhost:9042"

edg seed \
--driver cassandra \
--config examples/movr/cassandra.edg \
--url "localhost:9042"

edg run \
--driver cassandra \
--config examples/movr/cassandra.edg \
--url "localhost:9042" \
-w 10 \
-d 1m

edg deseed \
--driver cassandra \
--config examples/movr/cassandra.edg \
--url "localhost:9042"

edg down \
--driver cassandra \
--config examples/movr/cassandra.edg \
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
--config examples/movr/mongodb.edg \
--url "mongodb://localhost:27017/movr"

edg seed \
--driver mongodb \
--config examples/movr/mongodb.edg \
--url "mongodb://localhost:27017/movr"

edg run \
--driver mongodb \
--config examples/movr/mongodb.edg \
--url "mongodb://localhost:27017/movr" \
-w 10 \
-d 1m

edg deseed \
--driver mongodb \
--config examples/movr/mongodb.edg \
--url "mongodb://localhost:27017/movr"

edg down \
--driver mongodb \
--config examples/movr/mongodb.edg \
--url "mongodb://localhost:27017/movr"
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
--config examples/movr/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/movr"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg seed \
--driver spanner \
--config examples/movr/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/movr"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg run \
--driver spanner \
--config examples/movr/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/movr" \
-w 10 \
-d 1m

SPANNER_EMULATOR_HOST=localhost:9010 \
edg deseed \
--driver spanner \
--config examples/movr/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/movr"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg down \
--driver spanner \
--config examples/movr/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/movr"
```

## SQLite

### Setup

SQLite is embedded, so there's no container to start; the database file is created on first connect.

### Run

```sh
edg up \
--driver sqlite \
--config examples/movr/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg seed \
--driver sqlite \
--config examples/movr/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg run \
--driver sqlite \
--config examples/movr/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate" \
-w 10 \
-d 1m

edg deseed \
--driver sqlite \
--config examples/movr/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg down \
--driver sqlite \
--config examples/movr/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"
```
