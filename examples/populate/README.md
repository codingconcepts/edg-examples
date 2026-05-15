# Populate

A bulk data population example demonstrating `exec_batch` and `batch` functions to insert large volumes of data efficiently. Creates 1 million customers and their accounts using batched inserts of 10K rows at a time.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

```sh
edg up \
--driver pgx \
--config examples/populate/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/populate/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg deseed \
--driver pgx \
--config examples/populate/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/populate/crdb.yaml \
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
--config examples/populate/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/populate/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg deseed \
--driver mysql \
--config examples/populate/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/populate/mysql.yaml \
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
--config examples/populate/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/populate/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg deseed \
--driver oracle \
--config examples/populate/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/populate/oracle.yaml \
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
--config examples/populate/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=populate&encrypt=disable"

edg seed \
--driver mssql \
--config examples/populate/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=populate&encrypt=disable"

edg deseed \
--driver mssql \
--config examples/populate/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=populate&encrypt=disable"

edg down \
--driver mssql \
--config examples/populate/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=populate&encrypt=disable"
```
