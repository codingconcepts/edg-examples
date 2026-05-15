# E-Commerce

An e-commerce workload with categories, products, customers, and orders.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

```sh
edg up \
--driver pgx \
--config examples/ecommerce/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/ecommerce/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/ecommerce/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 100 \
-d 1m

edg deseed \
--driver pgx \
--config examples/ecommerce/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/ecommerce/crdb.yaml \
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
--config examples/ecommerce/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/ecommerce/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/ecommerce/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 100 \
-d 1m

edg deseed \
--driver mysql \
--config examples/ecommerce/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/ecommerce/mysql.yaml \
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
--config examples/ecommerce/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/ecommerce/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/ecommerce/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 100 \
-d 1m

edg deseed \
--driver oracle \
--config examples/ecommerce/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/ecommerce/oracle.yaml \
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
--config examples/ecommerce/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ecommerce&encrypt=disable"

edg seed \
--driver mssql \
--config examples/ecommerce/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ecommerce&encrypt=disable"

edg run \
--driver mssql \
--config examples/ecommerce/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ecommerce&encrypt=disable" \
-w 100 \
-d 1m

edg deseed \
--driver mssql \
--config examples/ecommerce/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ecommerce&encrypt=disable"

edg down \
--driver mssql \
--config examples/ecommerce/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=ecommerce&encrypt=disable"
```
