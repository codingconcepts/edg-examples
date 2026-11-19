# Signals: basic

The smallest useful signal: one table, one query, one curve.

A signal is an array of numbers computed once before the run starts.
`qps: signal('name', peak: N)` points a stage's rate limiter at it, so
the load follows any shape you can write as an expression rather than a
constant or a linear `ramp()`.

```edg
signal traffic(length: 120) {
  0.1 + 0.9 * pow(sin(pi * i / 119), 2)
}

stages {
  hump(workers: 8, duration: 2m, qps: signal('traffic', peak: 500))
}
```

Two things to know about that pair:

- **`peak` normalises the buffer.** The tallest point maps to 500 QPS
  and everything else scales against it. The shape above is written in
  0..1, so the run idles at 50 QPS and tops out at 500 - but a shape
  written in row counts would produce exactly the same curve.
- **With no `sim` block the buffer stretches across the whole run.** 120
  points over a 2-minute stage is one point per second; change
  `duration` and the same 120 points stretch or compress to fit. Values
  between points are interpolated, so the curve is smooth rather than a
  staircase.

For a shape that is easier to draw than to derive, `edg signal draw`
opens a bar editor in the terminal and exports what you draw as a signal
definition you can paste straight into this file:

```sh
edg signal draw --name traffic --peak 500
```

Resulting in something that might look like this:

```edg
signal traffic {
  [71.43, 71.43, 71.43, 142.86, 142.86, 142.86, 214.29, 285.71, 357.14, 500.00, 571.43, 571.43, 571.43, 500.00, 428.57, 357.14, 357.14, 285.71, 285.71, 285.71, 214.29, 214.29, 214.29, 214.29, 214.29, 214.29, 214.29, 214.29, 285.71, 285.71, 285.71, 357.14, 357.14, 357.14, 428.57, 428.57, 500.00, 571.43, 642.86, 714.29, 785.71, 928.57, 1000.00, 1000.00, 928.57, 928.57, 785.71, 714.29, 642.86, 571.43, 500.00, 428.57, 428.57, 357.14, 285.71, 214.29, 214.29, 214.29, 142.86, 142.86, 71.43, 71.43, 71.43, 71.43, 71.43]
}
```

A drawn signal needs no `length` and no `[i]`: edg counts the points in
the array and indexes them. Both are still accepted, so an export from
an older version pastes in unchanged.

The signal in this example *is* maths, and `edg signal explore` is the
other half of the pair: it plots an expression as you type it, so you
can see the curve before a run follows it:

```sh
edg signal explore --name traffic --length 120
```

It exports the expression with its length rather than a list of points:

```edg
signal traffic(length: 120) {
  0.1 + 0.9 * pow(sin(pi * i / 119), 2)
}
```

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Run

```sh
edg all \
--driver pgx \
--config examples/signals/crdb.edg \
--url "postgres://root@localhost:26257/defaultdb?sslmode=disable" \
--tui
```

`-w` and `-d` are not needed: the `stages` block sets both.

### Verify

`edg all` tears the table down at the end, so to look at the rows, run
the phases separately:

```sh
edg up  --driver pgx --config examples/signals/basic/crdb.edg --url "..."
edg run --driver pgx --config examples/signals/basic/crdb.edg --url "..."
```

Each row carries the instant it was written, so bucketing by elapsed
second recovers the curve the limiter followed:

```sql
WITH t AS (
  SELECT div(
    extract(epoch FROM ts)::INT - (SELECT extract(epoch FROM min(ts))::INT FROM events),
    10
  ) * 10 AS elapsed_s
  FROM events
)
SELECT elapsed_s, (count(*) / 10)::INT AS qps
FROM t
GROUP BY 1
ORDER BY 1;
```

One run, 8 workers against a three-node CockroachDB cluster:

```
  elapsed_s | qps
------------+------
          0 |  52
         10 | 107
         20 | 202
         30 | 317
         40 | 420
         50 | 485
         60 | 493
         70 | 444
         80 | 348
         90 | 234
        100 | 130
        110 |  65
        120 |   5
```

50 QPS at the floor, 500 at the midpoint, back to 50 - the declared
shape, measured. The last bucket is short because the run ends partway
through it.

Then clean up:

```sh
edg down --driver pgx --config examples/signals/basic/crdb.edg --url "..."
```

## See also

- [`examples/signals/cluster`](../cluster/) - the same workload driven
  by a cluster of agents.
- [`examples/qps_shapes`](../../qps_shapes/) - six shapes running
  concurrently across one simulated day.
- [`examples/correlated_signals`](../../correlated_signals/) - signals
  shaping the *data* rather than the rate.
