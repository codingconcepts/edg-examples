# Multi-Row DML

Demonstrates the `__values__` token for batch INSERT, UPSERT, and UPDATE operations. Instead of the `unnest(string_to_array(...))` / `JSON_TABLE` / `OPENJSON` patterns, `__values__` generates a standard multi-row `VALUES` clause:

```yaml
seed:
  - name: insert_products
    type: exec_batch
    count: 100
    size: 10
    args:
      - gen('productname')
      - uniform_f(1.00, 100.00, 2)
    query: |-
      INSERT INTO product (name, price)
      __values__
```

This produces a single statement per batch:

```sql
INSERT INTO product (name, price)
VALUES ('Widget', 9.99), ('Gadget', 24.50), ...
```

The `__values__` token works with any DML that accepts a `VALUES` clause or subquery:

- **INSERT**: `INSERT INTO t (cols) __values__`
- **Upsert (pgx)**: `INSERT INTO t (cols) __values__ ON CONFLICT (col) DO UPDATE SET ...`
- **Upsert (MySQL)**: `INSERT INTO t (cols) __values__ ON DUPLICATE KEY UPDATE ...`
- **Upsert (MSSQL)**: `MERGE INTO t USING (__values__) AS source(cols) ON ... WHEN MATCHED ...`
- **Update (pgx)**: `UPDATE t SET ... FROM (__values__) AS v(cols) WHERE t.id = v.id`
- **INSERT ALL (Oracle)**: `INSERT ALL __values__(t(col1, col2))`

> [!NOTE]
> `__values__` works with drivers that support standard multi-row VALUES syntax: pgx, mysql, mssql, spanner, and dsql. For Oracle, use the parameterized form `__values__(table(cols))` to generate `INSERT ALL ... SELECT 1 FROM DUAL`. For MongoDB and Cassandra, continue using the existing batch expansion patterns.

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
--config examples/multi_row_dml/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/multi_row_dml/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg deseed \
--driver pgx \
--config examples/multi_row_dml/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/multi_row_dml/crdb.yaml \
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
--config examples/multi_row_dml/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/multi_row_dml/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg deseed \
--driver mysql \
--config examples/multi_row_dml/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/multi_row_dml/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"
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
--config examples/multi_row_dml/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=multi_row_dml&encrypt=disable"

edg seed \
--driver mssql \
--config examples/multi_row_dml/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=multi_row_dml&encrypt=disable"

edg deseed \
--driver mssql \
--config examples/multi_row_dml/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=multi_row_dml&encrypt=disable"

edg down \
--driver mssql \
--config examples/multi_row_dml/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=multi_row_dml&encrypt=disable"
```

## Oracle

Oracle uses `INSERT ALL` instead of multi-row `VALUES`. The parameterized form `__values__(table(cols))` handles this automatically.

### Setup

```sh
docker compose -f infra/compose_oracle.yml up -d
```

### Run

```sh
edg up \
--driver oracle \
--config examples/multi_row_dml/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/multi_row_dml/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg deseed \
--driver oracle \
--config examples/multi_row_dml/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/multi_row_dml/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"
```
