# Objects

Demonstrates the `objects` config section, which defines reusable named arg templates. An object is a map of field names to expressions that queries can reference in two ways:

- **`object: order`** - expands all fields as positional args (`$1`, `$2`, ...) in declaration order
- **`obj('order').field`** - cherry-picks individual fields by name in `args` expressions

This example defines an **order** object with email, product, quantity, and timestamp fields. The `insert_order` query uses `object: order` to pass all fields, while `update_order` uses `obj('order').product` and `obj('order').quantity` to select only the fields it needs.

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
--config examples/objects/crdb.edg \
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
--config examples/objects/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 4 \
-d 10s
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
--config examples/objects/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 4 \
-d 10s
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
--config examples/objects/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=objects&encrypt=disable" \
-w 4 \
-d 10s
```
