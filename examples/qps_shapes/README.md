# QPS Shapes

A constant and a linear `ramp()` are the only load curves `qps` can describe on its own. `qps: signal('name', peak: N)` drives the rate limiter from a pre-computed signal buffer instead, so the shape of the load is anything you can write as an expression.

This example runs **six shapes at once** across one simulated day, compressed into six minutes of wall clock:

```edg
sim(period: '24h', in: '6m', from: '2024-06-03T00:00:00Z')
```

A business that operates around the clock does not see one shape at a time, so neither does this workload: the nightly batch, the hourly crons, the office hump and the background integrations all compete for the same database the whole day.

## The shapes

| Shape | Live | Rate contribution |
|---|---|---|
| `steady` | all day | Flat 0.3. Integrations, health checks, monitoring. |
| `etl` | 01:00-03:00 | Square. Off, full rate, off. |
| `workday` | 08:00-18:00 | Sine hump on a 5% floor, peaking at 13:00. |
| `spikes` | all day | A `cos^8` burst on every hour, on an 8% baseline. |
| `jitter` | all day | Broad sine hump multiplied by an `empirical.float()` draw. |
| `decay` | 22:00-24:00 | Quadratic run-down to the floor. |

Every signal is 288 points on a `5m` interval, so `i / 12.0` is the hour of day and one traversal of the buffer is one simulated day.

`peak` is required. The buffer is normalised rather than read raw - its maximum maps to `peak` QPS and everything else scales proportionally - so a 0..1 shape and a shape written in row counts behave identically.

## How six shapes share one limiter

Stages run one after another and a stage has one `qps`, so concurrent shapes cannot come from a stage each. Two declarations do it instead.

**A composite signal.** A signal expression can read the signals declared above it, so the rate the database actually sees is itself a signal:

```edg
signal total(from: '2024-06-03T00:00:00Z', to: '2024-06-04T00:00:00Z', interval: '5m') {
  signal_at ( 'steady' , i ) + signal_at ( 'etl' , i ) + ... + signal_at ( 'decay' , i )
}

stages {
  day(workers: 16, duration: 24h, qps: signal('total', peak: 1000))
}
```

**A per-iteration split.** `run_weights` are static integers, so they cannot follow a curve - a standalone conditional can. Each run item fires with its own shape's share of the current instant's total:

```edg
expr share = signal_at(args[0], int(sim_progress() * 288)) / signal_at('total', int(sim_progress() * 288))

run {
  if uniform.float(0.0, 1.0, 6) < share('workday') {
    record_workday(type: exec) `INSERT INTO events (ts, shape, load) VALUES ($1, 'workday', $2)` (
      sim_time(),
      load('workday')
    )
  }

  # ...one per shape
}
```

The shares sum to 1, so an iteration writes one row on average and a shape's expected rate is `peak x shape / total` - its own curve, scaled. Standalone `if` blocks and `run_weights` are mutually exclusive, which is fine here: the conditionals *are* the weights, recomputed every iteration.

## Noise as a shape

`jitter` is the only shape that is not purely deterministic. Random generators work inside signal expressions, but they are evaluated once per index while the buffer is built, so the result is a fixed rough-edged curve rather than live randomness - the same jitter replays every time the buffer wraps.

A generator on its own has no shape at all: draws are independent per index, so a signal of nothing but `empirical.float()` is frozen white noise. Multiplying a deterministic curve by a jitter factor centred on `1.0` keeps the shape and roughens it. In a composite, that draw also moves every other shape's share, so the exact split changes a little from run to run.

## What scales

| Declared | Runs as |
|---|---|
| `day(duration: 24h)` | 6m |
| `signal etl(interval: '5m')` | one buffer step every 1.25s |
| `peak: 1000` | 1,000 QPS |

`peak` is a rate, not a duration, so it stays as written - the same rule that leaves a flat `qps` alone. What sim compression does move is the *phase*: the buffer advances on the simulated clock, so 288 points at `5m` traverse the six-minute run exactly once.

## Running

Signals and `sim` are Pro features - set `EDG_LICENSE` or pass `--license`.

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Run

```sh
edg up \
--driver pgx \
--config examples/qps_shapes/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/qps_shapes/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
--pool-size 20
```

There's no `-d` flag: a staged run takes its length from the stages. Pass `--sim-in 20m` to watch the same shapes play out more slowly.

Each run item tags its rows with its shape, so the histograms below can tell them apart:

```
summary
Duration:  6m0.004s
Workers:   16

QUERY           COUNT  ERRORS  p90      p95      p99      QPS
record_decay    3480   0       1.238ms  1.407ms  2.27ms   9.7
record_etl      9810   0       1.332ms  1.566ms  2.672ms  27.2
record_jitter   59779  0       1.273ms  1.4ms    2.083ms  166.1
record_spikes   38983  0       1.24ms   1.369ms  2.193ms  108.3
record_steady   35872  0       1.335ms  1.504ms  2.409ms  99.6
record_workday  29406  0       1.205ms  1.315ms  2.182ms  81.7

Transactions:  177330
Errors:        0
tpm:           29554.7
```

The QPS column averages over the whole run, so a shape that is live for two simulated hours reads low. The histograms are where the shapes show up.

### Check

Connect

```sh
cockroach sql --insecure
```

The data spans a full simulated day:

```sql
SELECT
  min(ts),
  max(ts),
  max(ts) - min(ts) AS span,
  COUNT(*)
FROM events;
```

```
              min              |             max              |      span      | count
-------------------------------+------------------------------+----------------+---------
  2024-06-03 00:00:01.90375+00 | 2024-06-03 23:59:59.08748+00 | 23:59:57.18373 | 177330
```

Four shapes run from the first second to the last; the two with windows appear only inside theirs:

```sql
SELECT
  shape,
  min(ts)::TIME AS from_t,
  max(ts)::TIME AS to_t,
  COUNT(*) AS n
FROM events
GROUP BY shape
ORDER BY min(ts);
```

```
   shape  |     from_t     |      to_t      |   n
----------+----------------+----------------+--------
  spikes  | 00:00:01.90375 | 23:59:59.08748 | 38983
  jitter  | 00:00:03.58447 | 23:59:58.04464 | 59779
  workday | 00:00:04.01565 | 23:59:57.56771 | 29406
  steady  | 00:00:04.94541 | 23:59:54.90739 | 35872
  etl     | 01:00:00.14997 | 02:59:58.85711 |  9810
  decay   | 22:00:00.27498 | 23:54:29.6773  |  3480
```

#### The whole day, hour by hour

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
  hour |   n   |                   bar
-------+-------+-------------------------------------------
     0 |  4546 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     1 |  9457 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     2 |  9495 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     3 |  4801 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     4 |  5382 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     5 |  5569 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     6 |  6071 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     7 |  6532 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     8 |  6902 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     9 |  7977 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    10 |  9644 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    11 | 10780 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    12 | 11758 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    13 | 11633 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    14 | 10858 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    15 |  9186 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    16 |  7434 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    17 |  6436 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    18 |  5712 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    19 |  5180 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    20 |  4879 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    21 |  4716 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    22 |  7468 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    23 |  4914 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
```

The composite: a batch window overnight, a long climb to a midday peak, an afternoon decline, and a bump at 22:00 as the wind-down starts.

#### Six shapes at once

```sql
SELECT
  extract(hour FROM ts)::INT AS hour,
  count(*) FILTER (WHERE shape = 'steady')  AS steady,
  count(*) FILTER (WHERE shape = 'etl')     AS etl,
  count(*) FILTER (WHERE shape = 'workday') AS workday,
  count(*) FILTER (WHERE shape = 'spikes')  AS spikes,
  count(*) FILTER (WHERE shape = 'jitter')  AS jitter,
  count(*) FILTER (WHERE shape = 'decay')   AS decay
FROM events
GROUP BY hour
ORDER BY hour;
```

```
  hour | steady | etl  | workday | spikes | jitter | decay
-------+--------+------+---------+--------+--------+--------
     0 |   1565 |    0 |     263 |   1654 |   1064 |     0
     1 |   1484 | 4955 |     242 |   1624 |   1152 |     0
     2 |   1461 | 4855 |     246 |   1600 |   1333 |     0
     3 |   1416 |    0 |     265 |   1574 |   1546 |     0
     4 |   1556 |    0 |     268 |   1607 |   1951 |     0
     5 |   1522 |    0 |     260 |   1539 |   2248 |     0
     6 |   1535 |    0 |     245 |   1661 |   2630 |     0
     7 |   1494 |    0 |     260 |   1620 |   3158 |     0
     8 |   1507 |    0 |     357 |   1662 |   3376 |     0
     9 |   1460 |    0 |    1194 |   1640 |   3683 |     0
    10 |   1541 |    0 |    2583 |   1702 |   3818 |     0
    11 |   1444 |    0 |    3827 |   1611 |   3898 |     0
    12 |   1443 |    0 |    4736 |   1591 |   3988 |     0
    13 |   1487 |    0 |    4763 |   1603 |   3780 |     0
    14 |   1542 |    0 |    4014 |   1665 |   3637 |     0
    15 |   1513 |    0 |    2676 |   1650 |   3347 |     0
    16 |   1468 |    0 |    1267 |   1567 |   3132 |     0
    17 |   1545 |    0 |     462 |   1657 |   2772 |     0
    18 |   1513 |    0 |     266 |   1614 |   2319 |     0
    19 |   1439 |    0 |     226 |   1617 |   1898 |     0
    20 |   1486 |    0 |     262 |   1631 |   1500 |     0
    21 |   1483 |    0 |     235 |   1648 |   1350 |     0
    22 |   1425 |    0 |     265 |   1608 |   1176 |  2994
    23 |   1543 |    0 |     224 |   1638 |   1023 |   486
```

`steady` holds ~1,500 rows an hour from midnight to midnight and `spikes` ~1,620 (its bursts average flat at this resolution), while `workday` climbs 20x into its hump, `jitter` traces a broad rise and fall, and `etl` and `decay` occupy their windows. No stage boundaries anywhere: every column is competing for the same limiter the whole time.

#### The square window

```sql
SELECT
  to_char(date_trunc('hour', ts) + INTERVAL '30 minutes' * floor(extract(minute FROM ts) / 30), 'HH24:MI') AS bucket,
  COUNT(*) AS n,
  repeat('▒', (COUNT(*)::FLOAT8 / max(COUNT(*)) OVER () * 40)::INT) AS bar
FROM events
WHERE shape = 'etl'
GROUP BY bucket
ORDER BY bucket;
```

```
  bucket |  n   |                   bar
---------+------+-------------------------------------------
  01:00  | 2435 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  01:30  | 2520 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  02:00  | 2467 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  02:30  | 2388 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
```

Four buckets, nothing either side, all within 5% of each other. The edges are as sharp as the `cond()` that declared them.

#### The hourly bursts

`spikes` is live all day, so the hourly bucket flattens it. Drop to ten minutes:

```sql
SELECT
  to_char(date_trunc('hour', ts) + INTERVAL '10 minutes' * floor(extract(minute FROM ts) / 10), 'HH24:MI') AS bucket,
  COUNT(*) AS n,
  repeat('▒', (COUNT(*)::FLOAT8 / max(COUNT(*)) OVER () * 40)::INT) AS bar
FROM events
WHERE shape = 'spikes'
  AND ts >= '2024-06-03 12:00:00' AND ts < '2024-06-03 14:00:00'
GROUP BY bucket
ORDER BY bucket;
```

```
  bucket |  n  |                   bar
---------+-----+-------------------------------------------
  12:00  | 708 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  12:10  | 197 | ▒▒▒▒▒▒▒▒▒▒▒
  12:20  |  59 | ▒▒▒
  12:30  |  63 | ▒▒▒▒
  12:40  |  77 | ▒▒▒▒
  12:50  | 487 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  13:00  | 707 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  13:10  | 218 | ▒▒▒▒▒▒▒▒▒▒▒▒
  13:20  |  57 | ▒▒▒
  13:30  |  70 | ▒▒▒▒
  13:40  | 102 | ▒▒▒▒▒▒
  13:50  | 449 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
```

708 and 707 rows on consecutive hours: `cos^8` reproducing itself to within one row.

#### The empirical shape

At day scale, `jitter` is a hump:

```sql
SELECT
  extract(hour FROM ts)::INT AS hour,
  COUNT(*) AS n,
  repeat('▒', (COUNT(*)::FLOAT8 / max(COUNT(*)) OVER () * 40)::INT) AS bar
FROM events
WHERE shape = 'jitter'
GROUP BY hour
ORDER BY hour;
```

```
  hour |  n   |                   bar
-------+------+-------------------------------------------
     0 | 1064 | ▒▒▒▒▒▒▒▒▒▒▒
     1 | 1152 | ▒▒▒▒▒▒▒▒▒▒▒▒
     2 | 1333 | ▒▒▒▒▒▒▒▒▒▒▒▒▒
     3 | 1546 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     4 | 1951 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     5 | 2248 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     6 | 2630 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     7 | 3158 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     8 | 3376 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
     9 | 3683 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    10 | 3818 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    11 | 3898 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    12 | 3988 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    13 | 3780 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    14 | 3637 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    15 | 3347 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    16 | 3132 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    17 | 2772 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    18 | 2319 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    19 | 1898 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    20 | 1500 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    21 | 1350 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    22 | 1176 | ▒▒▒▒▒▒▒▒▒▒▒▒
    23 | 1023 | ▒▒▒▒▒▒▒▒▒▒
```

An hour holds twelve buffer points, so averaging hides the noise. Read the `load` column back at buffer resolution and the draw shows up:

```sql
SELECT
  to_char(date_trunc('hour', ts) + INTERVAL '5 minutes' * floor(extract(minute FROM ts) / 5), 'HH24:MI') AS bucket,
  round(max(load)::NUMERIC, 3) AS load,
  repeat('▒', (max(load)::FLOAT8 / max(max(load)) OVER () * 40)::INT) AS bar
FROM events
WHERE shape = 'jitter'
  AND ts >= '2024-06-03 06:00:00' AND ts < '2024-06-03 08:00:00'
GROUP BY bucket
ORDER BY bucket;
```

```
  bucket | load  |                   bar
---------+-------+-------------------------------------------
  06:00  | 0.616 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  06:05  | 0.629 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  06:10  | 0.626 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  06:15  | 0.613 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  06:20  | 0.641 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  06:25  | 0.655 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  06:30  | 0.648 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  06:35  | 0.671 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  06:40  | 0.663 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  06:45  | 0.695 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  06:50  | 0.694 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  06:55  | 0.689 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  07:00  | 0.666 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  07:05  | 0.703 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  07:10  | 0.655 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  07:15  | 0.692 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  07:20  | 0.732 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  07:25  | 0.727 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  07:30  | 0.653 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  07:35  | 0.776 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  07:40  | 0.703 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  07:45  | 0.788 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  07:50  | 0.796 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  07:55  | 0.802 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
```

Rising across the two hours as the underlying `sin^2` says it should, but never monotonically: 07:30 drops to 0.653 between neighbours at 0.727 and 0.776. That dip is a low draw from the CDF, and it stays in the buffer for the whole run - a noisy curve that is reproducible rather than merely random.

#### The wind-down

```sql
SELECT
  to_char(date_trunc('hour', ts) + INTERVAL '15 minutes' * floor(extract(minute FROM ts) / 15), 'HH24:MI') AS bucket,
  COUNT(*) AS n,
  repeat('▒', (COUNT(*)::FLOAT8 / max(COUNT(*)) OVER () * 40)::INT) AS bar
FROM events
WHERE shape = 'decay'
GROUP BY bucket
ORDER BY bucket;
```

```
  bucket |  n   |                   bar
---------+------+-------------------------------------------
  22:00  | 1091 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  22:15  |  840 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  22:30  |  610 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  22:45  |  453 | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  23:00  |  262 | ▒▒▒▒▒▒▒▒▒▒
  23:15  |  142 | ▒▒▒▒▒
  23:30  |   66 | ▒▒
  23:45  |   16 | ▒
```

`pow((24 - hour) / 2, 2)` as a curve of counts: each bucket roughly three quarters of the last.

#### Peaks against what was declared

`peak: 1000` is the composite's ceiling, so each shape's is a share of it: buffer maxima are 0.3 for `steady`, ~0.98 for `jitter` (it depends on the draw) and 1.0 for the rest, against a composite maximum of ~3.19. That puts the four unit shapes at about 314 QPS each and `steady` at about 94.

A `5m` simulated bucket is 1.25s of wall clock at 240x, so dividing by that converts rows per bucket into real QPS:

```sql
WITH buckets AS (
  SELECT
    shape,
    date_trunc('hour', ts) + INTERVAL '5 minutes' * floor(extract(minute FROM ts) / 5) AS bucket,
    COUNT(*) AS n
  FROM events
  GROUP BY shape, bucket
)
SELECT shape, (max(n) / 1.25)::INT AS peak_qps
FROM buckets
GROUP BY shape
ORDER BY peak_qps DESC;
```

```
   shape  | peak_qps
----------+-----------
  etl     |      358
  spikes  |      355
  workday |      355
  decay   |      320
  jitter  |      291
  steady  |      125
```

The four unit shapes land together. They read above 314 because `max()` over 288 buckets picks the luckiest one - each shape's arrivals are a random draw against its share, so the busiest bucket overstates the rate, most visibly for `steady`, whose 125 is the tallest of 288 buckets around a true 94. The mean rate over a flat window is the honest check: `etl` wrote 9,810 rows across two simulated hours, which is 30s of wall clock, for 327 QPS.

Set workers high enough to sustain the composite peak, exactly as for a flat `qps`. If the pool saturates, the limiter stops being the binding constraint and every shape flattens together.

#### Load values travel with the rows

Each query writes the buffer value that set its rate, so the payload and the arrival pattern come from the same declaration:

```sql
SELECT
  shape,
  round(min(load)::NUMERIC, 3) AS min_load,
  round(max(load)::NUMERIC, 3) AS max_load
FROM events
GROUP BY shape
ORDER BY shape;
```

```
   shape  | min_load | max_load
----------+----------+-----------
  decay   |    0.007 |    1.000
  etl     |    1.000 |    1.000
  jitter  |    0.161 |    0.999
  spikes  |    0.080 |    1.000
  steady  |    0.300 |    0.300
  workday |    0.050 |    1.000
```

Every curve's floor and ceiling, read back out of the table: the 5% `workday` floor, the 8% `spikes` baseline, the flat 0.3 of `steady`, and `etl` at exactly 1.0 for every row it wrote, because it only writes rows while its square window is up.

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/qps_shapes/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/qps_shapes/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
