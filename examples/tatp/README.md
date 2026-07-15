# TATP

Telecom Application Transaction Processing benchmark. Models a mobile phone subscriber database with 80% reads and 20% writes. Simple schema, designed for maximum throughput testing.

Transaction profiles (per TATP spec):

- **get_subscriber_data** (35%) - Point lookup by subscriber ID
- **get_access_data** (35%) - Access info lookup
- **update_location** (14%) - Update subscriber location
- **get_new_destination** (10%) - Call forwarding lookup
- **update_subscriber_data** (2%) - Toggle a subscriber bit
- **insert_call_forwarding** (2%) - Add a forwarding rule
- **delete_call_forwarding** (2%) - Remove a forwarding rule

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
--config examples/tatp/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/tatp/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/tatp/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 1m

edg deseed \
--driver pgx \
--config examples/tatp/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/tatp/crdb.edg \
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
--config examples/tatp/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/tatp/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/tatp/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 10 \
-d 1m

edg deseed \
--driver mysql \
--config examples/tatp/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/tatp/mysql.edg \
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
--config examples/tatp/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/tatp/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/tatp/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 10 \
-d 1m

edg deseed \
--driver oracle \
--config examples/tatp/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/tatp/oracle.edg \
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
--config examples/tatp/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tatp&encrypt=disable"

edg seed \
--driver mssql \
--config examples/tatp/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tatp&encrypt=disable"

edg run \
--driver mssql \
--config examples/tatp/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tatp&encrypt=disable" \
-w 10 \
-d 1m

edg deseed \
--driver mssql \
--config examples/tatp/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tatp&encrypt=disable"

edg down \
--driver mssql \
--config examples/tatp/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=tatp&encrypt=disable"
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
--config examples/tatp/cassandra.edg \
--url "localhost:9042"

edg seed \
--driver cassandra \
--config examples/tatp/cassandra.edg \
--url "localhost:9042"

edg run \
--driver cassandra \
--config examples/tatp/cassandra.edg \
--url "localhost:9042" \
-w 10 \
-d 1m

edg deseed \
--driver cassandra \
--config examples/tatp/cassandra.edg \
--url "localhost:9042"

edg down \
--driver cassandra \
--config examples/tatp/cassandra.edg \
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
--config examples/tatp/mongodb.edg \
--url "mongodb://localhost:27017/tatp"

edg seed \
--driver mongodb \
--config examples/tatp/mongodb.edg \
--url "mongodb://localhost:27017/tatp"

edg run \
--driver mongodb \
--config examples/tatp/mongodb.edg \
--url "mongodb://localhost:27017/tatp" \
-w 10 \
-d 1m

edg deseed \
--driver mongodb \
--config examples/tatp/mongodb.edg \
--url "mongodb://localhost:27017/tatp"

edg down \
--driver mongodb \
--config examples/tatp/mongodb.edg \
--url "mongodb://localhost:27017/tatp"
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
--config examples/tatp/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tatp"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg seed \
--driver spanner \
--config examples/tatp/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tatp"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg run \
--driver spanner \
--config examples/tatp/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tatp" \
-w 10 \
-d 1m

SPANNER_EMULATOR_HOST=localhost:9010 \
edg deseed \
--driver spanner \
--config examples/tatp/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tatp"

SPANNER_EMULATOR_HOST=localhost:9010 \
edg down \
--driver spanner \
--config examples/tatp/spanner.edg \
--url "projects/test-project/instances/test-instance/databases/tatp"
```
