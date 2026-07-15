# Index Comparison

A comparison test that demonstrates using expectations to validate that an indexed table outperforms an unindexed one. Two identical tables are created and seeded with the same volume of data. One with a secondary index on the `category` column, one without. The same lookup query runs against both, and expectations assert that the indexed path has lower latency.

```edg
expectations:
  - error_rate < 1
  - lookup_with_index.avg < lookup_without_index.avg
  - lookup_with_index.p99 < lookup_without_index.p99
```

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
--config examples/index_comparison/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 4 \
-d 10s
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
--config examples/index_comparison/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"
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
--config examples/index_comparison/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=index_comparison&encrypt=disable"
```
