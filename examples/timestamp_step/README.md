# Interval-Aligned Timestamps

Generates monotonically incrementing timestamps between two dates. The third argument to `timestamp_steps` determines the mode:

- **Interval mode** (string): provide a duration, count is derived.
- **Count mode** (integer): provide a row count, interval is derived.

Both modes set up state for `timestamp_step()`, which returns the next timestamp on each call.

## Key expressions

### Interval mode

```yaml
# Every 5 minutes for a year → 105,121 rows
count: timestamp_steps('2024-01-01T00:00:00Z', '2025-01-01T00:00:00Z', '5m')
args:
  - timestamp_step()
```

### Count mode

```yaml
# 10,000 evenly spaced timestamps across a year
count: timestamp_steps('2024-01-01T00:00:00Z', '2025-01-01T00:00:00Z', 10000)
args:
  - timestamp_step()
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
--config examples/timestamp_step/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/timestamp_step/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```

### Check

Connect:

```sh
cockroach sql --insecure
```

Verify events align to 5-minute boundaries:

```sql
SELECT
  occurred_at,
  extract(minute FROM occurred_at)::INT % 5 AS remainder
FROM events
ORDER BY occurred_at
LIMIT 20;
```

All `remainder` values should be `0`.

Verify metrics are evenly spaced (10,000 rows):

```sql
SELECT count(*) FROM metrics;

SELECT
  recorded_at,
  recorded_at - lag(recorded_at) OVER (ORDER BY recorded_at) AS gap
FROM metrics
ORDER BY recorded_at
LIMIT 20;
```

All `gap` values should be identical.

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/timestamp_step/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/timestamp_step/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```
