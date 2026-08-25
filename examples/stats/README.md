# Stats

Demonstrates the `stats` section, which runs observability queries at a fixed rate alongside the main workload, and the chart options that control how their values are displayed in the TUI.

Stats queries don't compete with workload queries for workers, and are hidden from the progress table by default (`include: true` shows them). Their print values always appear.

## Chart types

Set `type` on a stats query to choose how its print values are charted:

| Type | Shows |
|---|---|
| `line` (default) | The value over time |
| `bar` | A live frequency distribution of the value |

```edg
node_mix(
  type:       bar,
  post_print: { key: 'node', value: result().node_id, window: 10s }
) `SHOW node_id`
```

## Aggregation window

By default an aggregation covers the whole run, so a long run's numbers converge and stop reacting to what's happening now. Add `window` to aggregate over a sliding window instead:

```edg
live_rows(
  type:       line,
  post_print: { key: 'rows', value: result().rows, window: 30s }
) `SELECT count(*) AS rows FROM customer`
```

The window is rounded to the nearest multiple of `--print-interval` (default `1s`) and always covers at least one interval, so `window: 500ms` behaves the same as `window: 1s`.

## One line per distinct value

A bar chart shows you *what* the distribution is, but not how it got there. Add `series: value` to a line chart to plot one coloured line per distinct value the expression returns, with the y-axis showing how many times per second that value was seen:

```edg
node_over_time(
  type:       line,
  rate:       20 / 1s,
  post_print: { key: 'node', value: result().node_id, series: value, window: 5s }
) `SHOW node_id`
```

This is the shape you want for rolling upgrades, node drains, and rebalancing - anywhere the interesting signal is how a mix shifts over time. Poll fast (`rate: 20 / 1s` above) so each line has enough samples to be smooth.

Series keep their colour for the whole run, and a value that stops appearing drops to zero rather than vanishing, so you can watch a node leave the cluster or an old version drain away.

Values are treated as categorical even when they're numeric, so the stats table shows a frequency breakdown (`1=412 2=398 3=405`) rather than min/avg/max.

## CockroachDB

### Setup

The compose file runs three nodes behind HAProxy, so `SHOW node_id` returns a different node depending on which one the connection landed on.

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Run

```sh
edg all \
--driver pgx \
--config examples/stats/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
--tui \
--max-conn-lifetime 5s \
--max-conn-lifetime-jitter 2s \
-w 10 \
-d 2m
```

`--tui` is what renders the charts. The short connection lifetime recycles pooled connections across the three nodes, so the node id series actually move; without it a pool settles on whichever nodes it first connected to.
