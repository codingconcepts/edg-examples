# Config Includes

This example demonstrates the `include` directive for reusing reference data and expressions across workload files.

## Usage

Use `include` to pull in content from another file:

```edg
include 'shared/globals.edg'
include 'shared/schema.edg'
include 'shared/teardown.edg'
include 'shared/run_queries.edg'
```

Paths are resolved relative to the file containing the `include` directive.

## Structure

```
includes/
  crdb.edg                          # CockroachDB workload
  mysql.edg                         # MySQL workload
  oracle.edg                        # Oracle workload
  mssql.edg                         # MSSQL workload
  shared/
    globals.edg                     # Shared global variables (all databases)
    schema.edg                      # CockroachDB schema
    schema_mysql.edg                # MySQL schema
    schema_oracle.edg               # Oracle schema
    schema_mssql.edg                # MSSQL schema
    teardown.edg                    # CockroachDB teardown
    teardown_mysql.edg              # MySQL teardown
    teardown_oracle.edg             # Oracle teardown
    teardown_mssql.edg              # MSSQL teardown
    run_queries.edg                 # CockroachDB run queries
    run_queries_mysql.edg           # MySQL run queries
    run_queries_oracle.edg          # Oracle run queries
    run_queries_mssql.edg           # MSSQL run queries
```

## What can be included

An `include` merges the contents of another `.edg` file directly into the current file:

```edg
include 'shared/globals.edg'
include 'shared/schema.edg'
```

Includes must appear before all other declarations. Nested includes are supported (an included file can itself use `include`). Circular includes are detected and produce an error.

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
--config examples/includes/crdb.edg \
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
--config examples/includes/mysql.edg \
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
--config examples/includes/oracle.edg \
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
--config examples/includes/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=includes&encrypt=disable"
```
