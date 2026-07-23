# Custom Graph Metrics

Plot numeric `print` / `post_print` values as time-series graphs in TUI mode. When a workload config includes print expressions that return numeric values, the TUI gains a third tab (**Print**) showing both a summary table and a live chart.

This example tracks account balance statistics over time: total balance, average balance, and account count per region.

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
  --config examples/custom_graph_metrics/crdb.edg \
  --url "postgres://root@localhost:26257?sslmode=disable" \
  -w 1 \
  -d 1m \
  --tui
```

Press **Tab** to cycle between Log, Graph, and Print views. In the Print view:

- **Top**: aggregated print values (min/avg/max/n)
- **Bottom**: time-series chart of the selected metric
- **Left/Right**: cycle between `result().total_balance`, `result().avg_balance`, `result().account_count`
- **Up/Down**: change time window
- **1-9**: focus individual query series
