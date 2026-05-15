# Normal Distribution

Demonstrates `norm` and `norm_n` by generating product reviews with realistic rating distributions. Most ratings cluster around 4 stars (mean=4, stddev=1, clamped to 1-5).

## Functions

| Function | Signature | Description |
|---|---|---|
| `norm` | `norm(mean, stddev, min, max)` | Single normally-distributed random integer |
| `norm_n` | `norm_n(mean, stddev, min, max, minN, maxN)` | N unique normally-distributed integers (comma-separated) |

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

```sh
edg up \
--driver pgx \
--config examples/normal/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/normal/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/normal/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 30s
```

### Verify distribution

After running, check that ratings follow a bell curve around 4:

```sql
SELECT
  rating,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM review
GROUP BY rating
ORDER BY rating;
```

Example output:

```
  rating | total |                     histogram
---------+-------+-----------------------------------------------------
       1 |   319 | █
       2 |  3398 | █████████
       3 | 12644 | ████████████████████████████████
       4 | 19940 | ██████████████████████████████████████████████████
       5 | 13271 | █████████████████████████████████
```

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/normal/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/normal/crdb.yaml \
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
--config examples/normal/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg seed \
--driver mysql \
--config examples/normal/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/normal/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 10 \
-d 30s

edg deseed \
--driver mysql \
--config examples/normal/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/normal/mysql.yaml \
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
--config examples/normal/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg seed \
--driver oracle \
--config examples/normal/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/normal/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 10 \
-d 30s

edg deseed \
--driver oracle \
--config examples/normal/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/normal/oracle.yaml \
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
--config examples/normal/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=normal&encrypt=disable"

edg seed \
--driver mssql \
--config examples/normal/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=normal&encrypt=disable"

edg run \
--driver mssql \
--config examples/normal/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=normal&encrypt=disable" \
-w 10 \
-d 30s
```

### Teardown

```sh
edg deseed \
--driver mssql \
--config examples/normal/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=normal&encrypt=disable"

edg down \
--driver mssql \
--config examples/normal/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=normal&encrypt=disable"
```
