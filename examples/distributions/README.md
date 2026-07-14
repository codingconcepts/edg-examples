# Distributions

Demonstrates all thirteen distribution functions by writing values into a single table with a `dist_type` label, making it easy to compare histograms side by side.

## Functions

### Numeric distributions

| Function | Signature | Description |
|---|---|---|
| `uniform` | `uniform(min, max)` | Flat distribution, every value equally likely |
| `zipf` | `zipf(s, v, max)` | Power-law skew, low values dominate |
| `norm_f` | `norm_f(mean, stddev, min, max, precision)` | Bell curve centered on mean |
| `exp_f` | `exp_f(rate, min, max, precision)` | Exponential decay from min |
| `lognorm_f` | `lognorm_f(mu, sigma, min, max, precision)` | Right-skewed with a long tail |
| `pareto` | `pareto(alpha, max)` | Continuous power-law, lower values dominate |
| `beta_f` | `beta_f(alpha, beta, min, max, precision)` | Flexible shape in a bounded range |
| `gamma_f` | `gamma_f(shape, rate, min, max, precision)` | Right-skewed, models wait times |
| `weibull_f` | `weibull_f(shape, scale, min, max, precision)` | Reliability / time-to-failure |
| `poisson` | `poisson(lambda)` | Event count in a fixed interval |
| `rwalk_f` | `rwalk_f(group, start, drift, volatility, precision)` | Stateful random walk / Brownian motion |
| `binomial` | `binomial(n, p)` | Count of successes in n trials |
| `empirical` | `empirical(values)` | Sample from observed data via CDF |

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

Beta

```sql
SELECT
  (floor(d.value * 10) / 10)::DECIMAL(2,1) AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'beta'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
     0.0 |   330 | ████████████████████████
     0.1 |   678 | ██████████████████████████████████████████████████
     0.2 |   681 | ██████████████████████████████████████████████████
     0.3 |   562 | █████████████████████████████████████████
     0.4 |   351 | ██████████████████████████
     0.5 |   225 | █████████████████
     0.6 |    97 | ███████
     0.7 |    23 | ██
     0.8 |     6 |
```

Binomial

```sql
SELECT
  floor(d.value) AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'binomial'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |     3 |
       1 |    11 | █
       2 |    73 | ██████
       3 |   192 | █████████████████
       4 |   382 | ██████████████████████████████████
       5 |   552 | █████████████████████████████████████████████████
       6 |   564 | ██████████████████████████████████████████████████
       7 |   466 | █████████████████████████████████████████
       8 |   343 | ██████████████████████████████
       9 |   183 | ████████████████
      10 |    96 | █████████
      11 |    31 | ███
      12 |    10 | █
      13 |     3 |
```

Empirical

```sql
SELECT
  floor(d.value / 7) * 7 AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'empirical'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |   129 | ████████
       7 |   713 | ██████████████████████████████████████████
      14 |   214 | █████████████
      21 |   240 | ██████████████
      28 |   850 | ██████████████████████████████████████████████████
      35 |   112 | ███████
      42 |   109 | ██████
      49 |    94 | ██████
      56 |    77 | █████
      63 |    75 | ████
      70 |    70 | ████
      77 |   119 | ███████
      84 |   146 | █████████
      91 |   104 | ██████
```

Exponential

```sql
SELECT
  floor(d.value) AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'exponential'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |  1244 | ██████████████████████████████████████████████████
       1 |   759 | ███████████████████████████████
       2 |   437 | ██████████████████
       3 |   273 | ███████████
       4 |   149 | ██████
       5 |   110 | ████
       6 |    56 | ██
       7 |    43 | ██
       8 |    22 | █
       9 |    12 |
      10 |     7 |
      11 |    14 | █
      12 |     5 |
      13 |     3 |
      14 |     3 |
```

Gamma

```sql
SELECT
  floor(d.value / 2) * 2 AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'gamma'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |   804 | ████████████████████████████████████████
       2 |  1007 | ██████████████████████████████████████████████████
       4 |   639 | ████████████████████████████████
       6 |   299 | ███████████████
       8 |   143 | ███████
      10 |    86 | ████
      12 |    29 | █
      14 |    16 | █
      16 |     6 |
      18 |     3 |
      20 |     1 |
      22 |     1 |
```

Log-normal

```sql
SELECT
  floor(d.value / 3) * 3 AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'lognormal'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |   122 | ██████
       3 |   891 | ██████████████████████████████████████████████
       6 |   964 | ██████████████████████████████████████████████████
       9 |   514 | ███████████████████████████
      12 |   254 | █████████████
      15 |   106 | █████
      18 |    56 | ███
      21 |    31 | ██
      24 |    11 | █
      27 |     3 |
      30 |     2 |
      33 |     1 |
      48 |     1 |
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
       0 |     5 |
       7 |    16 | █
      14 |    70 | ██████
      21 |   134 | ███████████
      28 |   260 | ██████████████████████
      35 |   457 | ██████████████████████████████████████
      42 |   544 | ██████████████████████████████████████████████
      49 |   595 | ██████████████████████████████████████████████████
      56 |   452 | ██████████████████████████████████████
      63 |   329 | ████████████████████████████
      70 |   177 | ███████████████
      77 |    57 | █████
      84 |    33 | ███
      91 |     4 |
```

Pareto

```sql
SELECT
  floor(d.value / 3) * 3 AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'pareto'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |  2790 | ██████████████████████████████████████████████████
       3 |   135 | ██
       6 |    35 | █
       9 |     9 |
      12 |     7 |
      15 |     1 |
      18 |     1 |
      21 |     1 |
      63 |     1 |
```

Poisson

```sql
SELECT
  floor(d.value) AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'poisson'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |    26 | ██
       1 |   112 | ███████████
       2 |   267 | ██████████████████████████
       3 |   417 | ████████████████████████████████████████
       4 |   522 | ██████████████████████████████████████████████████
       5 |   513 | █████████████████████████████████████████████████
       6 |   441 | ██████████████████████████████████████████
       7 |   299 | █████████████████████████████
       8 |   202 | ███████████████████
       9 |    90 | █████████
      10 |    59 | ██████
      11 |    27 | ███
      12 |    16 | ██
      13 |     5 |
      14 |     1 |
      16 |     1 |
```

Random walk

```sql
SELECT
  floor(d.value / 3) * 3 AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'rwalk'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
      18 |    13 | █
      21 |    54 | ████
      24 |    32 | ██
      27 |    25 | ██
      30 |    39 | ███
      33 |    46 | ███
      36 |    45 | ███
      39 |   270 | ███████████████████
      42 |   392 | ████████████████████████████
      45 |   542 | ██████████████████████████████████████
      48 |   663 | ███████████████████████████████████████████████
      51 |   567 | ████████████████████████████████████████
      54 |   706 | ██████████████████████████████████████████████████
      57 |   418 | ██████████████████████████████
      60 |   300 | █████████████████████
      63 |   114 | ████████
```

Uniform

```sql
SELECT
  floor(d.value / 7) * 7 AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'uniform'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |   211 | █████████████████████████████████████████████
       7 |   198 | ██████████████████████████████████████████
      14 |   214 | ██████████████████████████████████████████████
      21 |   222 | ████████████████████████████████████████████████
      28 |   212 | █████████████████████████████████████████████
      35 |   224 | ████████████████████████████████████████████████
      42 |   208 | █████████████████████████████████████████████
      49 |   203 | ████████████████████████████████████████████
      56 |   233 | ██████████████████████████████████████████████████
      63 |   177 | ██████████████████████████████████████
      70 |   205 | ████████████████████████████████████████████
      77 |   203 | ████████████████████████████████████████████
      84 |   191 | █████████████████████████████████████████
      91 |   204 | ████████████████████████████████████████████
      98 |    73 | ████████████████
```

Weibull

```sql
SELECT
  floor(d.value / 7) * 7 AS bucket,
  count(*) AS total,
  repeat('█', (count(*) * 50 / max(count(*)) OVER ())::INT) AS histogram
FROM distributions d
WHERE d.dist_type = 'weibull'
GROUP BY 1
ORDER BY 1;

  bucket | total |                     histogram
---------+-------+-----------------------------------------------------
       0 |   161 | ███████████████████████
       7 |   287 | ██████████████████████████████████████████
      14 |   305 | ████████████████████████████████████████████
      21 |   318 | ██████████████████████████████████████████████
      28 |   343 | ██████████████████████████████████████████████████
      35 |   288 | ██████████████████████████████████████████
      42 |   300 | ████████████████████████████████████████████
      49 |   243 | ███████████████████████████████████
      56 |   227 | █████████████████████████████████
      63 |   159 | ███████████████████████
      70 |   128 | ███████████████████
      77 |   103 | ███████████████
      84 |   100 | ███████████████
      91 |    69 | ██████████
      98 |    17 | ██
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
       0 |  2620 | ██████████████████████████████████████████████████
       7 |   574 | ███████████
      14 |   331 | ██████
      21 |   236 | █████
      28 |   187 | ████
      35 |   133 | ███
      42 |    96 | ██
      49 |    99 | ██
      56 |    85 | ██
      63 |    64 | █
      70 |    71 | █
      77 |    66 | █
      84 |    63 | █
      91 |    41 | █
      98 |    17 |
```

### Markov chain

The `markov` function produces string states rather than numeric values, so it uses a separate table:

```edg
up {
  create_orders `CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    status STRING NOT NULL
  )`
}

run {
  insert_order(type: exec)
    `INSERT INTO orders (status) VALUES ($1)` (
    markov('order_status',
      ['pending', 'processing', 'shipped', 'delivered', 'returned'],
      [
        0.2, 0.8, 0.0, 0.0, 0.0,
        0.0, 0.3, 0.7, 0.0, 0.0,
        0.0, 0.0, 0.2, 0.8, 0.0,
        0.0, 0.0, 0.0, 0.95, 0.05,
        0.7, 0.0, 0.0, 0.0, 0.3
      ]
    )
  )
}
```

```sql
SELECT status, count(*) AS total
FROM orders
GROUP BY 1
ORDER BY 2 DESC;

    status   | total
-------------+--------
  delivered  |  2953
  processing |   236
  returned   |   221
  shipped    |   214
  pending    |   195
```

Most rows end up in `delivered` because it has the highest stay probability (0.95). The chain cycles: returned orders flow back to pending, creating a realistic order lifecycle.

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
