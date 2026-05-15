# Batch Types

Demonstrates `query_batch` and `exec_batch` query types. A `query_batch` inserts products and captures the returned rows, then an `exec_batch` references those rows to insert reviews against them.

- **`query_batch`** evaluates args per row (controlled by `count` and `size`), generates a multi-row `VALUES` clause via `__values__`, and stores the query results for use by `ref_*` functions.
- **`exec_batch`** does the same arg generation but executes without reading results.

Both types use the `__values__` token to produce a single `INSERT ... VALUES (...), (...), ...` statement per batch. For Oracle, the parameterized form `__values__(table(cols))` generates `INSERT ALL ... SELECT 1 FROM DUAL` syntax.

> [!NOTE]
> MySQL and Oracle do not support `INSERT...RETURNING`, so the MySQL and Oracle configs use `exec_batch` + a follow-up `query` to fetch inserted rows instead of `query_batch`.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

```sh
edg up \
--driver pgx \
--config examples/batch/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/batch/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg deseed \
--driver pgx \
--config examples/batch/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/batch/crdb.yaml \
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
--config examples/batch/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/batch/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg deseed \
--driver mysql \
--config examples/batch/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/batch/mysql.yaml \
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
--config examples/batch/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/batch/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg deseed \
--driver oracle \
--config examples/batch/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/batch/oracle.yaml \
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
--config examples/batch/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=batch&encrypt=disable"

edg seed \
--driver mssql \
--config examples/batch/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=batch&encrypt=disable"

edg deseed \
--driver mssql \
--config examples/batch/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=batch&encrypt=disable"

edg down \
--driver mssql \
--config examples/batch/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=batch&encrypt=disable"
```
