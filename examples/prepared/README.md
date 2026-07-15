# Prepared

Demonstrates `prepared: true` for run queries using a multi-table e-commerce schema (customer, product, purchase_order, order_item). The complex joins and aggregations make server-side parse/plan overhead significant enough that prepared statements show a measurable performance advantage.

The CockroachDB config includes both prepared and non-prepared variants of each query for side-by-side comparison.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Run

```sh
edg all \
--driver pgx \
--config examples/prepared/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```

## MySQL

### Setup

```sh
docker compose -f infra/compose_mysql.yml up -d
```

### Run

```sh
edg all \
--driver mysql \
--config examples/prepared/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"
```

## Oracle

### Setup

```sh
docker compose -f infra/compose_oracle.yml up -d
```

### Run

```sh
edg all \
--driver oracle \
--config examples/prepared/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"
```

## MSSQL

### Setup

```sh
docker compose -f infra/compose_mssql.yml up -d
```

### Run

```sh
edg all \
--driver mssql \
--config examples/prepared/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=bank&encrypt=disable"
```
