# Stats

Demonstrates the `stats` section, which runs observability queries at a fixed rate alongside the main workload, and the chart options that control how their values are displayed in the TUI.

Stats queries don't compete with workload queries for workers, and are hidden from the progress table by default (`include: true` shows them). Their print values always appear.

## Chart types

Set `type` on a stats query to choose how its print values are charted:

| Type | Shows |
|---|---|
| `line` (default) | The value over time |
| `bar` | A live frequency distribution of the value |
| `gauge` | One bar per print expression, sized by its latest value |

```edg
node_mix(
  type:       bar,
  post_print: { key: 'node', value: result().node_id, window: 10s }
) `SHOW node_id`
```

A bar chart counts how often each distinct value was seen, so a numeric metric renders as equal-height bars that only ever grow. For current-state numbers you want a gauge, whose bars rise and fall with the value itself:

```edg
ranges(
  type:       gauge,
  post_print: { key: 'under',       value: result().under },
  post_print: { key: 'unavailable', value: result().unavailable }
) `SELECT
    sum(under_replicated_ranges)::INT8 AS under,
    sum(unavailable_ranges)::INT8 AS unavailable
  FROM system.replication_stats`
```

All the bars share one y-axis, so metrics with very different magnitudes flatten each other - put those in separate stats blocks.

## Block layout

By default the chart shows one query at a time and you page between them with ←/→. Set `layout` on the block to put its queries on a single page:

| Layout | Shows |
|---|---|
| `page` (default) | One query per page |
| `merge` | Every query in one chart, sharing axes |
| `split` | Each query's chart side-by-side, all on one shared scale |

```edg
stats (rate: 1 / 5s, layout: split) {
  customer_ranges(type: gauge, post_print: { key: 'ranges',       value: result().n }) `...`
  customer_leaseholders(type: gauge, post_print: { key: 'leaseholders', value: result().n }) `...`
}
```

Use `split` when the metrics each need their own chart but still have to be read against each other. Every chart on the page is drawn to the same scale, taken from the largest value any of them plots, so one peaking at 3 next to one peaking at 1700 reads as the smaller thing it is. Use `merge` when they belong on one set of axes; it requires every query in the block to have the same chart type.

Either way the scale is shared, so put metrics orders of magnitude apart in separate blocks - otherwise the larger one squashes the smaller.

`layout` applies within a block, so separate blocks stay separate pages. `split` falls back to paging when the terminal can't give each chart about 24 columns.

## Chart smoothing

A rate sampled once a second is noise on top of a trend, so charts smooth it by default: each point is averaged with the ones within five print intervals of it. The window is centred, so a spike stays where it happened.

`smooth` on the block overrides the run's `--chart-smoothing`:

| Value | Draws |
|---|---|
| `avg` (default) | Each point averaged with its neighbours |
| `max` | Each bucket's peak, unsmoothed |
| `none` | The samples raw |
| a duration, e.g. `10s` | Averaged as `avg`, over the window you name |

```edg
stats (rate: 20 / 1s, smooth: none) {
  node_over_time_raw(
    type:       line,
    post_print: { key: 'node', value: result().node_id, series: value, window: 5s }
  ) `SHOW node_id`
}
```

The chart scales itself to what it plots, so smoothing shows up as a lower peak on the y-axis rather than as a flatter-looking line. Percentile charts keep their peaks either way.

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
