# Data Drift Over Time

Five tables where distributions and values shift as the workload runs, each demonstrating different math functions with `global_iter()`.

## Drift patterns

| Table | Pattern | Functions used |
|---|---|---|
| `product_views` | Zipf skew interpolates from uniform to concentrated | `zipf()`, `global_iter()` |
| `price_history` | Logarithmic growth that rises quickly then plateaus | `log()`, `floor()` |
| `traffic_log` | Sine wave seasonality riding on a growing baseline | `sin()`, `pi`, `sqrt()`, `abs()`, `floor()` |
| `error_events` | Periodic cosine-squared spikes every N iterations | `cos()`, `pow()`, `mod()`, `pi` |
| `sensor_calibration` | Bounded sqrt drift via arctangent saturation curve | `sqrt()`, `atan()`, `pi` |

## Key expressions

**Logarithmic price growth** - fast initial rise, then plateau:
```
floor(base_price * (1.0 + log(1.0 + global_iter() / 1000.0)) * 100.0) / 100.0
```

**Seasonal traffic with trend** - sine wave on a growing baseline:
```
floor(abs(base_traffic + 0.5 * sqrt(global_iter()) + amplitude * sin(2.0 * pi * global_iter() / period)))
```

**Periodic error spikes** - cosine-squared pulse:
```
pow(cos(pi * mod(global_iter(), interval) / interval), 2.0) * 10.0
```

**Bounded sensor drift** - arctangent saturation (asymptotically approaches 15):
```
100.0 + (2.0 * atan(sqrt(global_iter()) / 100.0) / pi) * 15.0 + noise
```

## Running

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Run

```sh
edg all \
--driver pgx \
--config examples/temporal_patterns/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

# Or separately.
edg up \
--driver pgx \
--config examples/temporal_patterns/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/temporal_patterns/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 1m
```

### Check

Connect

```sh
cockroach sql --insecure
```

Zipf skew drift - top product's share should grow over time:
```sql
SELECT
  bucket,
  count(*) AS total,
  count(*) FILTER (WHERE product_id = 0) AS top_product,
  round((count(*) FILTER (WHERE product_id = 0))::FLOAT8 / count(*)::FLOAT8 * 100, 1) AS top_pct,
  repeat('▒', (round((count(*) FILTER (WHERE product_id = 0))::FLOAT8 / count(*)::FLOAT8 * 40))::INT) AS histogram
FROM (
  SELECT *, ntile(10) OVER (ORDER BY iteration) AS bucket
  FROM product_views
)
GROUP BY bucket
ORDER BY bucket;
```

Output

```
  bucket | total | top_product | top_pct |                histogram
---------+-------+-------------+---------+-------------------------------------------
       1 |  2644 |        1225 |    46.3 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       2 |  2643 |        1959 |    74.1 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       3 |  2643 |        2440 |    92.3 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       4 |  2643 |        2593 |    98.1 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       5 |  2643 |        2632 |    99.6 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       6 |  2643 |        2637 |    99.8 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       7 |  2643 |        2641 |    99.9 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       8 |  2643 |        2642 |     100 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       9 |  2643 |        2643 |     100 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      10 |  2643 |        2643 |     100 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
```

Logarithmic price plateau - average price per bucket should rise steeply then flatten:
```sql
SELECT
  bucket,
  round(avg(price)::NUMERIC, 2) AS avg_price,
  round(min(price)::NUMERIC, 2) AS min_price,
  round(max(price)::NUMERIC, 2) AS max_price,
  repeat('▒', (round(avg(price) / max(avg(price)) OVER () * 40))::INT) AS histogram
FROM (
  SELECT *, ntile(10) OVER (ORDER BY iteration) AS bucket
  FROM price_history
)
GROUP BY bucket
ORDER BY bucket;
```

Output

```
 bucket | avg_price | min_price | max_price |                histogram
---------+-----------+-----------+-----------+-------------------------------------------
       1 |    105.75 |     50.09 |    139.66 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       2 |    156.93 |    139.67 |    170.72 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       3 |    185.96 |    170.73 |    200.89 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       4 |    211.99 |    200.90 |    221.88 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       5 |    229.27 |    221.89 |    236.09 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       6 |    242.19 |    236.10 |    247.77 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       7 |    252.52 |    247.78 |    256.94 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       8 |    260.88 |    256.95 |    264.72 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       9 |    268.11 |    264.72 |    271.35 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      10 |    274.40 |    271.35 |    277.37 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
```

Sine wave traffic - request counts should oscillate around a rising baseline:
```sql
SELECT
  bucket,
  round(avg(request_count)::NUMERIC, 1) AS avg_requests,
  min(request_count) AS min_requests,
  max(request_count) AS max_requests,
  repeat('▒', (round(avg(request_count) / max(avg(request_count)) OVER () * 40))::INT) AS histogram
FROM (
  SELECT *, ntile(20) OVER (ORDER BY iteration) AS bucket
  FROM traffic_log
)
GROUP BY bucket
ORDER BY bucket;
```

Output

```
  bucket | avg_requests | min_requests | max_requests |                histogram
---------+--------------+--------------+--------------+-------------------------------------------
       1 |        149.5 |          101 |          186 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       2 |        212.8 |          186 |          236 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       3 |        248.8 |          236 |          257 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       4 |        253.9 |          247 |          257 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       5 |        232.8 |          215 |          247 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       6 |        192.7 |          170 |          215 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       7 |        147.7 |          127 |          170 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       8 |        111.6 |          100 |          127 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       9 |         96.9 |           96 |          100 | ▒▒▒▒▒▒▒▒▒▒▒▒
      10 |        107.2 |           98 |          121 | ▒▒▒▒▒▒▒▒▒▒▒▒▒
      11 |        142.9 |          121 |          167 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      12 |        199.3 |          167 |          229 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      13 |        256.6 |          229 |          282 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      14 |        301.4 |          283 |          316 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      15 |        322.7 |          316 |          325 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      16 |        315.4 |          303 |          324 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      17 |        282.0 |          258 |          302 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      18 |        233.1 |          209 |          258 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      19 |        186.0 |          167 |          209 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      20 |        154.7 |          148 |          167 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
```

Periodic error spikes - severity peaks at regular intervals then drops to near zero:
```sql
SELECT
  bucket,
  round(avg(severity)::NUMERIC, 2) AS avg_severity,
  round(max(severity)::NUMERIC, 2) AS max_severity,
  repeat('▒', (round(avg(severity) / max(avg(severity)) OVER () * 40))::INT) AS histogram
FROM (
  SELECT *, ntile(20) OVER (ORDER BY iteration) AS bucket
  FROM error_events
)
GROUP BY bucket
ORDER BY bucket;
```

Output

```
  bucket | avg_severity | max_severity |                histogram
---------+--------------+--------------+-------------------------------------------
       1 |         8.06 |        10.00 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       2 |         1.43 |         4.67 | ▒▒▒▒▒▒
       3 |         2.85 |         6.56 | ▒▒▒▒▒▒▒▒▒▒▒▒
       4 |         9.05 |        10.00 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       5 |         6.34 |         9.58 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       6 |         0.59 |         2.20 | ▒▒▒
       7 |         4.52 |         8.16 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       8 |         9.38 |        10.00 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       9 |         4.34 |         8.12 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      10 |         0.52 |         1.97 | ▒▒
      11 |         5.91 |         9.36 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      12 |         9.21 |        10.00 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      13 |         3.37 |         7.09 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      14 |         1.09 |         3.91 | ▒▒▒▒▒
      15 |         7.41 |         9.92 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      16 |         8.50 |        10.00 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      17 |         2.03 |         5.37 | ▒▒▒▒▒▒▒▒▒
      18 |         1.92 |         5.11 | ▒▒▒▒▒▒▒▒
      19 |         8.37 |        10.00 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      20 |         7.42 |         9.96 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
```

Sensor calibration drift - drift_offset should grow quickly then saturate:
```sql
SELECT
  bucket,
  round(avg(drift_offset)::NUMERIC, 3) AS avg_drift,
  round(avg(reading)::NUMERIC, 2) AS avg_reading,
  repeat('▒', (round(avg(drift_offset) / max(avg(drift_offset)) OVER () * 40))::INT) AS histogram
FROM (
  SELECT *, ntile(10) OVER (ORDER BY iteration) AS bucket
  FROM sensor_calibration
)
GROUP BY bucket
ORDER BY bucket;
```

Output

```
  bucket | avg_drift | avg_reading |                histogram
---------+-----------+-------------+-------------------------------------------
       1 |     6.068 |      106.06 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       2 |     9.114 |      109.12 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       3 |    10.209 |      110.22 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       4 |    10.853 |      110.86 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       5 |    11.292 |      111.30 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       6 |    11.621 |      111.62 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       7 |    11.866 |      111.87 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       8 |    12.068 |      112.05 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       9 |    12.235 |      112.21 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
      10 |    12.376 |      112.37 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
```

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/temporal_patterns/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/temporal_patterns/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```