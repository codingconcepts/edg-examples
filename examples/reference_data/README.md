# Reference Data

Demonstrates the `reference` config section, which loads static datasets into memory without a database query. Reference data is available to all `ref_*` functions (`ref_rand`, `ref_same`, `ref_diff`, etc.) just like `init` query results.

This example defines a **regions** reference dataset with names and cities, then uses `ref_same` to seed customers with a consistent region and city from the same row.

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
--config examples/reference_data/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/reference_data/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg deseed \
--driver pgx \
--config examples/reference_data/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/reference_data/crdb.edg \
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
--config examples/reference_data/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/reference_data/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg deseed \
--driver mysql \
--config examples/reference_data/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/reference_data/mysql.edg \
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
--config examples/reference_data/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/reference_data/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg deseed \
--driver oracle \
--config examples/reference_data/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/reference_data/oracle.edg \
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
--config examples/reference_data/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=reference_data&encrypt=disable"

edg seed \
--driver mssql \
--config examples/reference_data/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=reference_data&encrypt=disable"

edg deseed \
--driver mssql \
--config examples/reference_data/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=reference_data&encrypt=disable"

edg down \
--driver mssql \
--config examples/reference_data/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=reference_data&encrypt=disable"
```
