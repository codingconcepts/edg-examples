# Time Compression

A full day of ecommerce traffic - overnight lull, morning ramp, midday plateau, evening peak, wind-down - in a 2 minute run. The `sim` block does all of it:

```edg
sim(period: '24h', in: '2m', from: '2024-06-03T00:00:00Z')
```

The scale factor is `period / in`, so 720x. Every duration in the config is written in real-world units and read as simulated time.

## What scales

| Declared | Runs as |
|---|---|
| `overnight(duration: 6h)` | 30s |
| `morning_ramp(duration: 4h, ramp_duration: 2h)` | 20s, ramping over 10s |
| `midday(duration: 8h)` | 40s |
| `evening_peak(duration: 4h)` | 20s |
| `wind_down(duration: 2h)` | 10s |
| `hourly_rollup(rate: 1/1h)` | fires every 5s, ~24 times |

`qps` is a rate, not a duration, so it stays as written. The run keeps the declared **shape** at 1/720 of the volume: `qps: 600` over a simulated hour lands 3000 rows rather than 2.16 million.

`sim_time()` stamps each row with the simulated instant, so the data spans a real 24 hours even though the run took 2 minutes.

## Running

`sim` is a Pro feature - set `EDG_LICENSE` or pass `--license`.

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Run

```sh
edg up \
--driver pgx \
--config examples/time_compression/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/time_compression/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
--pool-size 30
```

There's no `-d` flag: a staged run takes its length from the stages. `edg` logs both readings per stage:

```
INFO sim period=24h in=2m scale=720x
INFO stage name=overnight workers=2 duration=30s simulated=6h0m0s qps=40
```

### Check

Connect

```sh
cockroach sql --insecure
```

The data spans a full simulated day, not 2 minutes:

```sql
SELECT
  min(ts),
  max(ts),
  max(ts) - min(ts) AS span,
  COUNT(*)
FROM events;
```

```
min                            max                            span             count
2024-06-03 00:00:00.22527+00   2024-06-03 23:59:35.56914+00   23:59:35.34387   59123
```

The declared load curve is reproduced hour by hour:

```sql
SELECT
  extract(hour FROM ts)::INT AS hour,
  COUNT(*) AS n,
  repeat('▒', (COUNT(*)::FLOAT8 / max(COUNT(*)) OVER () * 40)::INT) AS bar
FROM events
GROUP BY hour
ORDER BY hour;
```

```
hour  n     bar
0     200   ▒
...
7     2242  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
8     3000  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
...
19    6000  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
...
23    497   ▒▒▒
```

The background worker keeps to its simulated cadence - one rollup per simulated hour:

```sql
SELECT COUNT(*) AS rollups FROM hourly_rollup;
```

```
rollups
23
```

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/time_compression/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/time_compression/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
