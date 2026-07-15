# Correlated Signals

Four tables driven by two pre-computed signal buffers (`traffic` and `promo_boost`), simulating a week of correlated observability data in a 5-minute run. Each table reads from the signals at different lags and correlation strengths using `signal_at()` and `global_iter()`.

## Signal definitions

| Signal | Shape | Length |
|---|---|---|
| `traffic` | Daily sine wave (period 288 = 24h at 5m intervals) + weekly sine (period 2016) | 2016 (7 days × 288/day) |
| `promo_boost` | Sharp periodic spikes via cosine^20, every ~500 iterations | 2016 |

## Correlation patterns

| Table | Signal source | Lag | Correlation | Effect |
|---|---|---|---|---|
| `page_views` | `traffic` + `promo_boost` | 0 | 1.0 (direct) | Exact signal sum - the "ground truth" |
| `orders` | `traffic` | 3 iterations (15m) | 0.7 | Orders follow traffic with short delay and moderate noise |
| `support_tickets` | `traffic` | 24 iterations (2h) | 0.3 | Tickets lag traffic by 2 hours, mostly noise |
| `server_errors` | `promo_boost` | 6 iterations (30m) | 0.5 | Errors spike after promos, half signal half noise |

## Key expressions

**Direct signal read** - page views track the raw signal:
```
signal_at('traffic', global_iter()) + signal_at('promo_boost', global_iter())
```

**Lagged correlation with noise** - orders follow traffic with 15-minute delay:
```
floor(abs(signal_at('traffic', global_iter() - 3) * 0.7 + norm(0, 300, -500, 500) * 0.3))
```

**Timestamp from iteration** - maps `global_iter()` to a week of 5-minute intervals, wrapping at 2016:
```sql
'2024-01-01T00:00:00Z'::TIMESTAMPTZ + (mod($1, 2016) * INTERVAL '5 minutes')
```

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
--config examples/correlated_signals/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/correlated_signals/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 1 \
-d 5m
```

### Check

Connect

```sh
cockroach sql --insecure
```

Daily traffic pattern - view counts should show sine wave across 24h buckets:
```sql
SELECT
  extract(hour FROM ts) AS hour,
  round(avg(view_count)::NUMERIC, 0) AS avg_views,
  repeat('▒', (round(avg(view_count) / max(avg(view_count)) OVER () * 40))::INT) AS histogram
FROM page_views
GROUP BY hour
ORDER BY hour;
```

Order-traffic correlation - orders should loosely follow page views with a lag:
```sql
SELECT
  extract(hour FROM v.ts)::INT AS hour,
  repeat('▒', (round(avg(v.view_count) / max(avg(v.view_count)) OVER () * 20))::INT) AS views,
  repeat('▒', (round(avg(o.order_count) / max(avg(o.order_count)) OVER () * 20))::INT) AS orders
FROM page_views v
JOIN orders o ON date_trunc('hour', v.ts) = date_trunc('hour', o.ts)
GROUP BY extract(hour FROM v.ts)
ORDER BY hour
LIMIT 24;
```

Promo boost spikes - errors should spike shortly after promo periods:
```sql
SELECT
  date_trunc('hour', ts) AS hour,
  sum(error_count) AS total_errors,
  repeat('▒', greatest(1, (round(sum(error_count)::FLOAT8 / max(sum(error_count)::FLOAT8) OVER () * 40))::INT)) AS histogram
FROM server_errors
GROUP BY hour
ORDER BY hour
LIMIT 24;
```

Ticket lag - support tickets should trail traffic peaks by ~2 hours:
```sql
SELECT
  extract(hour FROM v.ts)::INT AS hour,
  repeat('▒', (round(avg(v.view_count) / max(avg(v.view_count)) OVER () * 20))::INT) AS traffic,
  repeat('▒', greatest(1, (round(avg(t.ticket_count) / max(avg(t.ticket_count)) OVER () * 20))::INT)) AS tickets
FROM page_views v
JOIN support_tickets t ON date_trunc('hour', v.ts) = date_trunc('hour', t.ts)
GROUP BY extract(hour FROM v.ts)
ORDER BY hour
LIMIT 24;
```

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/correlated_signals/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/correlated_signals/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
