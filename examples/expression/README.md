# Expressions

Demonstrates the built-in [expr-lang](https://expr-lang.org/docs/language-definition) features available in any query argument or user-defined expression. These complement edg's custom functions (gen, ref_rand, distributions, etc.) and can be freely combined with them.

## Features

| Category | Functions / Operators |
|---|---|
| Array predicates | `all`, `any`, `one`, `none` |
| Array search | `find`, `findIndex`, `findLast`, `findLastIndex` |
| Array transform | `filter`, `map`, `sort`, `sortBy`, `reverse`, `uniq`, `concat`, `flatten` |
| Array aggregate | `reduce`, `mean`, `median`, `first`, `last`, `take` |
| Map | `keys`, `values`, `groupBy` |
| String operators | `contains`, `startsWith`, `endsWith`, `matches`, `in` |
| String functions | `trimPrefix`, `trimSuffix`, `splitAfter`, `repeat`, `indexOf`, `lastIndexOf`, `hasPrefix`, `hasSuffix` |
| Type conversion | `type`, `toJSON`, `fromJSON`, `toBase64`, `fromBase64`, `toPairs`, `fromPairs` |
| Operators | `..` (range), `[:]` (slice), `?.` (optional chaining), `??` (nil coalescing), `if`/`else` |
| Bitwise | `bitand`, `bitor`, `bitxor`, `bitnand`, `bitnot`, `bitshl`, `bitshr`, `bitushr` |
| Language | `let` bindings, `#` predicates, closures |
| Misc | `len`, `get` |

> **Note:** edg's custom `sum`, `min`, `max`, `count`, `date`, and `duration` functions shadow the expr built-ins of the same name. Use `reduce()` for array totals and the edg-specific functions for dates and distributions.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

```sh
edg up \
--driver pgx \
--config examples/expression/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/expression/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 1 \
-d 5s

edg deseed \
--driver pgx \
--config examples/expression/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/expression/crdb.yaml \
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
--config examples/expression/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/expression/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 1 \
-d 5s

edg deseed \
--driver mysql \
--config examples/expression/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/expression/mysql.yaml \
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
--config examples/expression/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/expression/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 1 \
-d 5s

edg deseed \
--driver oracle \
--config examples/expression/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/expression/oracle.yaml \
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
--config examples/expression/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=expression&encrypt=disable"

edg run \
--driver mssql \
--config examples/expression/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=expression&encrypt=disable" \
-w 1 \
-d 5s

edg deseed \
--driver mssql \
--config examples/expression/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=expression&encrypt=disable"

edg down \
--driver mssql \
--config examples/expression/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=expression&encrypt=disable"
```
