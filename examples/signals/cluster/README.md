# Signals: cluster

The [basic](../basic/) workload - one table, one query, one curve - run
by a cluster of agents instead of one `edg` process.

The config is unchanged. A signal-driven stage has no fixed per-agent
rate to push, so the coordinator sends every agent the whole curve and
the peak it was declared with, and each agent divides that peak by the
number of agents running the job:

```
rate = buffer[i] / max(buffer) * peak / agents
```

So `peak: 500` is what the *cluster* peaks at, not what each agent peaks
at. `workers: 8` is per agent. If an agent joins or drops out mid-run,
the coordinator broadcasts the new count and the divisor changes - the
shape does not.

Position is measured from the start of the run rather than the start of
the stage, and an agent that joins late is told how far into the run it
is, so it picks the curve up where everyone else is rather than
restarting it at index 0.

## Setup

Start CockroachDB:

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

Create the coordination database:

```sh
cockroach sql --insecure -e "CREATE DATABASE edg_cluster"
```

## Run

Start the coordinator:

```sh
edg cluster coordinator \
  --crdb-url "postgres://root@localhost:26257/edg_cluster?sslmode=disable"
```

Start two agents, in separate terminals:

```sh
edg cluster agent \
  --crdb-url "postgres://root@localhost:26257/edg_cluster?sslmode=disable" \
  --region us-east
```

```sh
edg cluster agent \
  --crdb-url "postgres://root@localhost:26257/edg_cluster?sslmode=disable" \
  --region eu-west
```

Check they registered:

```sh
edg cluster agents | jq
```

Submit the workload:

```sh
edg cluster submit \
  --target-url "postgres://root@localhost:26257/defaultdb?sslmode=disable" \
  --config examples/signals/crdb.edg \
  --workers 4 \
  --stream
```

`--duration` is ignored here: the `stages` block sets it.

## Verify

The streamed log reports `per_agent_qps=0` for a signal-driven stage -
there is no fixed rate to report, because each agent samples the curve
itself. The shape shows up in the rows:

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

Two agents, 8 workers each, against a three-node CockroachDB cluster:

```
  elapsed_s | qps
------------+------
          0 |  58
         10 | 113
         20 | 211
         30 | 326
         40 | 427
         50 | 488
         60 | 492
         70 | 437
         80 | 339
         90 | 224
        100 | 123
        110 |  62
        120 |   1
```

33,004 rows, against 32,998 for the same config on a single instance.
Doubling the agents doubled the workers, not the load: the curve is
run-wide and the two agents took half of it each.

## Teardown

```sh
edg cluster reset \
  --crdb-url "postgres://root@localhost:26257/edg_cluster?sslmode=disable"
```

## See also

- [`examples/signals/basic`](../basic/) - the same workload on a single
  instance.
- [`examples/cluster`](../../cluster/) - cluster mode on its own,
  including shaping a submission with `--env`.
