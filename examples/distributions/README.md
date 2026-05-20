# Distributions

Demonstrates all five distribution functions by writing values into a single table with a `dist_type` label, making it easy to compare histograms side by side.

## Functions

### Numeric distributions

| Function | Signature | Description |
|---|---|---|
| `uniform` | `uniform(min, max)` | Flat distribution, every value equally likely |
| `zipf` | `zipf(s, v, max)` | Power-law skew, low values dominate |
| `norm_f` | `norm_f(mean, stddev, min, max, precision)` | Bell curve centered on mean |
| `exp_f` | `exp_f(rate, min, max, precision)` | Exponential decay from min |
| `lognorm_f` | `lognorm_f(mu, sigma, min, max, precision)` | Right-skewed with a long tail |

### Set distributions

Pick from a predefined set of values using a distribution to control which items are selected most often.

| Function | Signature | Description |
|---|---|---|
| `set_rand` | `set_rand(values, weights)` | Uniform or weighted random selection from a set |
| `set_norm` | `set_norm(values, mean, stddev)` | Normal distribution over indices; `mean` index picked most often |
| `set_exp` | `set_exp(values, rate)` | Exponential distribution over indices; lower indices picked most often |
| `set_lognorm` | `set_lognorm(values, mu, sigma)` | Log-normal distribution over indices; right-skewed selection |
| `set_zipf` | `set_zipf(values, s, v)` | Zipfian distribution over indices; strong power-law skew toward first items |

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
--config examples/distributions/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/distributions/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 10s
```

### Check

Exponential

```sql
SELECT
  floor(d.value / 7) * 7 AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'exponential'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |     3 |
       7 |    17 | ██
      14 |    46 | ██████
      21 |   100 | █████████████
      28 |   167 | ██████████████████████
      35 |   308 | ████████████████████████████████████████
      42 |   382 | ██████████████████████████████████████████████████
      49 |   362 | ███████████████████████████████████████████████
      56 |   322 | ██████████████████████████████████████████
      63 |   236 | ███████████████████████████████
      70 |   115 | ███████████████
      77 |    49 | ██████
      84 |    21 | ███
      91 |     2 |
```

Log normal

```sql
SELECT
  floor(d.value / 7) * 7 AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'lognormal'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |  1002 | ██████████████████████████████████████████████████
       7 |   926 | ██████████████████████████████████████████████
      14 |   175 | █████████
      21 |    35 | ██
      28 |     6 |
      35 |     1 |
      42 |     1 |
```

Normal

```sql
SELECT
  floor(d.value / 7) * 7 AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'normal'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |     3 |
       7 |    17 | ██
      14 |    46 | ██████
      21 |   100 | █████████████
      28 |   167 | ██████████████████████
      35 |   308 | ████████████████████████████████████████
      42 |   382 | ██████████████████████████████████████████████████
      49 |   362 | ███████████████████████████████████████████████
      56 |   322 | ██████████████████████████████████████████
      63 |   236 | ███████████████████████████████
      70 |   115 | ███████████████
      77 |    49 | ██████
      84 |    21 | ███
      91 |     2 |
```

Pareto

```sql
SELECT
  floor(d.value / 7) * 7 AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'pareto'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |  2125 | ██████████████████████████████████████████████████
       7 |    24 | █
      14 |     4 |
      21 |     1 |
```

Uniform

```sql
SELECT
  div(d.value - 1, 50) * 50 + 1 AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'uniform'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |   152 | ███████████████████████████████████████████
       7 |   156 | ████████████████████████████████████████████
      14 |   158 | █████████████████████████████████████████████
      21 |   140 | ████████████████████████████████████████
      28 |   152 | ███████████████████████████████████████████
      35 |   145 | █████████████████████████████████████████
      42 |   151 | ███████████████████████████████████████████
      49 |   137 | ███████████████████████████████████████
      56 |   163 | ██████████████████████████████████████████████
      63 |   140 | ████████████████████████████████████████
      70 |   176 | ██████████████████████████████████████████████████
      77 |   173 | █████████████████████████████████████████████████
      84 |   129 | █████████████████████████████████████
      91 |   148 | ██████████████████████████████████████████
      98 |    35 | ██████████
```

Zipfian

```sql
SELECT
  floor(d.value / 7) * 7 AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'zipfian'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |  1940 | ██████████████████████████████████████████████████
       7 |    90 | ██
      14 |    37 | █
      21 |    19 |
      28 |    11 |
      35 |     7 |
      42 |     7 |
      49 |     6 |
      56 |     1 |
      63 |     2 |
      77 |     1 |
      84 |     1 |
```

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/distributions/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/distributions/crdb.yaml \
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
--config examples/distributions/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg run \
--driver mysql \
--config examples/distributions/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
-w 10 \
-d 30s

edg deseed \
--driver mysql \
--config examples/distributions/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/distributions/mysql.yaml \
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
--config examples/distributions/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg run \
--driver oracle \
--config examples/distributions/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb" \
-w 10 \
-d 30s

edg deseed \
--driver oracle \
--config examples/distributions/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/distributions/oracle.yaml \
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
--config examples/distributions/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=distributions&encrypt=disable"

edg run \
--driver mssql \
--config examples/distributions/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=distributions&encrypt=disable" \
-w 10 \
-d 30s

edg deseed \
--driver mssql \
--config examples/distributions/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=distributions&encrypt=disable"

edg down \
--driver mssql \
--config examples/distributions/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=distributions&encrypt=disable"
```
