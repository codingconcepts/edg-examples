# Seasonal Cookbook

Fourteen season shapes in one config, graded from a single term to a five-level platform, so you can copy the one nearest the shape you need. Each writes 20,000 rows into `events` under its own `shape` label, apart from the last, which writes into `regional_events`.

For the retail-and-support walkthrough, see [seasonal](../seasonal/).

> `season` is a licensed feature. Set `EDG_DEV_KEY` or pass `--license`.

## Shapes

Every count below comes from `edg stage --config examples/seasonal_cookbook/crdb.edg -f csv --rng-seed 1`, so it is the config's actual output rather than an estimate.

### One term at a time

| Shape | Term | Measured over 20,000 rows |
|---|---|---|
| `weekly` | `weekdays` | Weekdays ~3,550 each, Sat and Sun ~1,100. The weekend takes 11% against 28.6% flat |
| `daily` | `hours` | 18:00 peaks at 1,761, 01:00 troughs at 80 |
| `annual` | `months` | August 2,816, February 875. January and February share a weight but not a count (914 vs 875), which is the 31/29 ratio of their lengths |
| `office` | `business_hours` | 91% of rows in `[9, 17)`; ~2,300 per in-hours hour against ~117 per hour outside, the 20:1 that `off: 0.05` asks for |
| `growth` | `recency` | 2024 takes 16,042 rows to 2023's 3,958. December 2024 alone (2,318) is four times the whole of Q1 2023 (577) |
| `launch` | `spikes` | The launch week takes 37% of six months of data, March 56%. `width` is the half-width, so the spike is a fortnight wide in total |

### Composing terms

Terms multiply. Each is an independent shape, and a bucket's weight is their product.

| Shape | Terms | Measured over 20,000 rows |
|---|---|---|
| `etl` | `hours` × `weekdays` | 51% of rows in the four hours from 23:00 to 03:00, 12% at the weekend |
| `saas` | `recency` × `weekdays` × `business_hours` | Half-years run 284, 2,866, 5,608, 11,242; 83% in weekday office hours |
| `shutdown` | `weekdays` × two `mag < 1` spikes | 3-17 August takes 329 rows against 890 for the same window in July; the Christmas lull pulls December to 1,290 against a ~1,750 monthly baseline |
| `billing` | `weight` | Six days of each month carry 56% of the year: ~2,000 on the 1st, 2nd, 28th, 29th and 30th against ~350 mid-month (and 1,197 on the 31st, since only seven months have one) |

### Interactions and multi-level shifts

`months` and `hours` each shape their own axis, so multiplying them can only scale a fixed daily curve up and down. A daily curve whose *shape* changes with the month is an interaction, and interactions live in `weight`.

**`summer_evenings`** walks the peak hour between 13:00 and 21:00 across the year. Mean hour of day by month:

| Jan | Feb | Mar | Apr | May | Jun | Jul | Aug | Sep | Oct | Nov | Dec |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 13.0 | 13.6 | 14.9 | 17.1 | 18.8 | 20.4 | 20.9 | 20.4 | 18.6 | 16.9 | 14.7 | 13.6 |

**`summer_evenings_coarse`** is the same expression without `bucket: '1h'`, and is in the config to show the trap. Only declarative terms drive the default bucket, so a `weight`-only season gets `24h`, samples the expression at midnight where `hour` is always 0, and the daily shape *aliases* into a yearly one: hours flatten to 790-880 rows each (noise), while July collects 3,252 rows against January's 282. Nothing errors, so check the shape you asked for actually landed.

**`platform`** stacks five terms and a step change, and each level shows up on its own:

| Level | Term | Measured |
|---|---|---|
| Year-on-year growth | `recency` | 2023: 4,149, 2024: 15,851 |
| Quarter-end reporting | `months` | On 2023, before the step change: June 410 vs May 283, September 444 vs August 315, December 613 vs November 419 |
| Working week | `weekdays` | Tuesday 4,150, Sunday 1,009 |
| Working day | `hours` | 09:00 peaks at 1,613, 01:00 troughs at 188 |
| Release-day surge | `spikes[0]` | 792 rows over 13-15 May against a 185-row May norm for three days |
| Six-hour outage | `spikes[1]`, `mag: 0.05` | 11 rows in the window against 23 the day before |
| Migration step change | `weight` | 14.0 rows/day in Jan-Feb 2024, 35.3 in Mar-Apr |
| Month-end batch | `weight` | 17.4% of rows on days 28-31, against the 11.4% those days are of the range |

The step change lives in `weight` rather than `recency` because a regime shift is a cliff and `recency` is a smooth curve; they compose, so growth continues either side of the cliff.

**`eu` / `us` / `apac`** are one season per region, chosen per row with a ternary, which only evaluates the branch it takes:

```
region: set(['eu', 'us', 'apac'], [50, 35, 15]),
ts: arg('region') == 'eu' ? season('eu') : arg('region') == 'us' ? season('us') : season('apac')
```

Each region keeps at least 92% of its rows inside its own working day. Summed, `regional_events` has no quiet night: a 22:00 UTC trough of 115 rows where APAC has finished and the Americas have not started, against ~1,800 an hour across the 13:00-16:00 EU/US overlap. `business_hours` can't wrap midnight, which is why the APAC day is an `hours` array.

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
--config examples/seasonal_cookbook/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/seasonal_cookbook/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```

### Check

Connect

```sh
cockroach sql --insecure
```

Any shape's hour-of-day curve, swapping in `weekly`, `etl`, `platform` and so on:

```sql
SELECT
  extract(hour FROM ts)::INT AS hour,
  count(*) AS events,
  repeat('▒', (round(count(*)::FLOAT8 / max(count(*)) OVER () * 40))::INT) AS histogram
FROM events
WHERE shape = 'daily'
GROUP BY hour
ORDER BY hour;
```

Month-of-year curve for the annual shapes:

```sql
SELECT
  extract(month FROM ts)::INT AS month,
  count(*) AS events,
  repeat('▒', (round(count(*)::FLOAT8 / max(count(*)) OVER () * 40))::INT) AS histogram
FROM events
WHERE shape = 'annual'
GROUP BY month
ORDER BY month;
```

The interaction, and the same expression sampled too coarsely. The mean hour should walk through the year for `summer_evenings` and stay flat for `summer_evenings_coarse`, whose rows pile into summer instead:

```sql
SELECT
  shape,
  extract(month FROM ts)::INT AS month,
  count(*) AS events,
  round(avg(extract(hour FROM ts))::NUMERIC, 1) AS avg_hour
FROM events
WHERE shape IN ('summer_evenings', 'summer_evenings_coarse')
GROUP BY shape, month
ORDER BY shape, month;
```

The platform step change - the daily rate should roughly double from March 2024:

```sql
SELECT
  date_trunc('month', ts)::DATE AS month,
  count(*) AS events,
  round(count(*)::NUMERIC / extract(day FROM date_trunc('month', ts) + INTERVAL '1 month' - INTERVAL '1 day'), 1) AS per_day
FROM events
WHERE shape = 'platform' AND ts >= '2024-01-01' AND ts < '2024-05-01'
GROUP BY month
ORDER BY month;
```

Follow the sun - each region busy in its own window, the total busy all day:

```sql
SELECT
  extract(hour FROM ts)::INT AS utc_hour,
  count(*) FILTER (WHERE region = 'eu') AS eu,
  count(*) FILTER (WHERE region = 'us') AS us,
  count(*) FILTER (WHERE region = 'apac') AS apac,
  count(*) AS total
FROM regional_events
GROUP BY utc_hour
ORDER BY utc_hour;
```

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/seasonal_cookbook/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/seasonal_cookbook/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
