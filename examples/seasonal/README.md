# Seasonal

Two years of orders whose `created_at` timestamps follow a retail calendar, plus a year of support tickets that follow the working week. Both come from `season` blocks, which draw timestamps from a weighted distribution instead of spreading them evenly.

> `season` is a licensed feature. Set `EDG_DEV_KEY` or pass `--license`.

For a graded set of fourteen shapes, from a single term to multi-level interactions, see [seasonal_cookbook](../seasonal_cookbook/).

## Season definitions

| Season | Range | Bucket | Shape |
|---|---|---|---|
| `retail` | 2023-01-01 to 2025-01-01 | `1h` | Q4 ramp, Fri/Sat peak, evening peak, Black Friday spikes, recency bias, post-Christmas lull |
| `support` | 2024-01-01 to 2025-01-01 | `1h` (default) | Office hours only, weekdays only |

Terms multiply, so a Saturday evening in late November picks up the month, weekday, hour and spike weights all at once.

| Term | Meaning |
|---|---|
| `months` | 12 weights, January first |
| `weekdays` | 7 weights, Sunday first |
| `hours` | 24 weights, midnight first |
| `business_hours` | `{ from, to, off }` - `off` is the out-of-hours multiplier, so `off: 0.05` is 20x less likely than a business hour. Blind to the day of week, so it composes with `weekdays` |
| `recency` | `{ half_life }` - exponential bias towards `to` |
| `spikes` | `[{ at, width, mag }]` - peak of magnitude `mag` at `at`, tapering linearly to 1 over `width` either side |
| `weight` | Arbitrary expression per bucket, with `t`, `year`, `month`, `day`, `yearday`, `weekday` and `hour` in scope |

## Key expressions

**Draw a timestamp** - the season decides when the row happened:
```
season('retail')
```

**Scale a column by the same season** - `arg('created_at')` reads the value already generated for this row, so the weight matches that row's own timestamp:
```
int(1 + norm.float(2, 1, 0, 7, 0) * sqrt(season_weight('retail', arg('created_at'))))
```

`season_weight()` is normalised so an average bucket is `1.0`. Peak weight in this config is around 47, so the basket size is damped with `sqrt` to stay plausible. The raw weight is also written to `intensity`, which makes the correlation easy to check in SQL.

## Measured output

From `edg stage --config examples/seasonal/crdb.edg -f json` (20,000 orders, 5,000 tickets):

| Check | Result |
|---|---|
| Orders per year | 2023: 6,662, 2024: 13,338 - the 1-year `half_life` gives a 2:1 skew |
| 2024 by month | Nov 4,066, Dec 2,595, Feb 387 - Q4 dominates |
| Black Friday (27-30 Nov 2024) | 2,247 orders, 11% of two years in 4 of 731 days |
| Post-Christmas (26-31 Dec 2024) | 5.3% of December, against 19.4% if December were flat |
| Peak hour | 18:00 (1,662), trough 02:00 (82) |
| Busiest weekdays | Fri 3,376 and Sat 3,359, quietest Mon 2,306 |
| Average basket | 8.25 items in Nov 2024, 2.02 in Feb 2024 |
| Tickets in office hours | 4,677 of 5,000; only 459 at the weekend |

## Running

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Run

```sh
edg up \
--driver pgx \
--config examples/seasonal/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/seasonal/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```

### Check

Connect

```sh
cockroach sql --insecure
```

Monthly shape - November and December should tower over the rest:
```sql
SELECT
  date_trunc('month', created_at)::DATE AS month,
  count(*) AS orders,
  repeat('▒', (round(count(*)::FLOAT8 / max(count(*)) OVER () * 40))::INT) AS histogram
FROM orders
GROUP BY month
ORDER BY month;
```

Daily shape - an evening peak and a quiet early morning:
```sql
SELECT
  extract(hour FROM created_at)::INT AS hour,
  count(*) AS orders,
  repeat('▒', (round(count(*)::FLOAT8 / max(count(*)) OVER () * 40))::INT) AS histogram
FROM orders
GROUP BY hour
ORDER BY hour;
```

Black Friday spike - four days should hold a double-digit share of two years:
```sql
SELECT
  count(*) FILTER (WHERE created_at BETWEEN '2024-11-27' AND '2024-12-01') AS black_friday,
  count(*) AS total,
  round(100.0 * count(*) FILTER (WHERE created_at BETWEEN '2024-11-27' AND '2024-12-01') / count(*), 1) AS pct
FROM orders;
```

Correlated columns - baskets should grow with intensity:
```sql
SELECT
  width_bucket(intensity, 0, 20, 5) AS intensity_band,
  round(avg(intensity)::NUMERIC, 2) AS avg_intensity,
  round(avg(item_count)::NUMERIC, 2) AS avg_items,
  count(*) AS orders
FROM orders
GROUP BY intensity_band
ORDER BY intensity_band;
```

Support tickets - office hours only, and quiet at the weekend:
```sql
SELECT
  extract(dow FROM opened_at)::INT AS dow,
  count(*) FILTER (WHERE extract(hour FROM opened_at) BETWEEN 8 AND 17) AS in_hours,
  count(*) FILTER (WHERE extract(hour FROM opened_at) NOT BETWEEN 8 AND 17) AS out_of_hours
FROM tickets
GROUP BY dow
ORDER BY dow;
```

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/seasonal/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/seasonal/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
