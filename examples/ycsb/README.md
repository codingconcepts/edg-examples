# YCSB

A Yahoo! Cloud Serving Benchmark implementation with all 6 workload profiles (A-F) using Zipfian key distribution. Switch between profiles by changing `run_weights` in the config.

Workload profiles:

- **A** - Update heavy: 50% read, 50% update
- **B** - Read mostly: 95% read, 5% update
- **C** - Read only: 100% read
- **D** - Read latest: 95% read, 5% insert
- **E** - Short ranges: 95% scan, 5% insert
- **F** - Read-modify-write: 50% read, 50% read-modify-write

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

```sh
edg up \
--driver pgx \
--config examples/ycsb/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/ycsb/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/ycsb/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 100 \
-d 1m

edg deseed \
--driver pgx \
--config examples/ycsb/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/ycsb/crdb.yaml \
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
--config examples/ycsb/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/ycsb/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/ycsb/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 100 \
-d 1m

edg deseed \
--driver mysql \
--config examples/ycsb/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/ycsb/mysql.yaml \
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
--config examples/ycsb/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/ycsb/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/ycsb/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 100 \
-d 1m

edg deseed \
--driver oracle \
--config examples/ycsb/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/ycsb/oracle.yaml \
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
--config examples/ycsb/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ycsb&encrypt=disable"

edg seed \
--driver mssql \
--config examples/ycsb/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ycsb&encrypt=disable"

edg run \
--driver mssql \
--config examples/ycsb/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ycsb&encrypt=disable" \
-w 100 \
-d 1m

edg deseed \
--driver mssql \
--config examples/ycsb/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ycsb&encrypt=disable"

edg down \
--driver mssql \
--config examples/ycsb/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ycsb&encrypt=disable"
```
