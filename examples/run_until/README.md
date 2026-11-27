# Run Until A Predicate Holds

Most stages run for a fixed `duration`. Some work doesn't have one: purging old rows, backfilling a new column, draining a queue. It takes as long as it takes, and you want to measure what it does to the database while it happens.

`until` is a boolean expression on a `run` query, evaluated after each execution. Once it holds, that lane stops.

```edg
run {
  purge_events(type: exec, helper: true, until: affected() < purge_batch)
    `DELETE FROM event
     WHERE id IN (
       SELECT id FROM event
       WHERE created_at < now() - INTERVAL '30 days'
       LIMIT $1::INT
     )` (purge_batch)
}
```

`affected()` is how many rows the statement touched. A `DELETE ... LIMIT 5000` returns 5000 every time until the last one, so `affected() < purge_batch` is "the table is clear".

## `helper`

A stage that declares no weights runs every run item in turn, and a weighted stage picks one at random. Either way, a purge query declared alongside ordinary traffic gets interleaved with it and drains at a fraction of the rate.

`helper: true` keeps a run item out of that mix. It runs only where a stage's weights name it, which is what lets the purge have a lane to itself.

`edg doctor` warns about a helper no weights block ever names, since nothing can then schedule it.

## What ends, and when

```edg
stages {
  backfill(duration: 1h) {
    drain(workers: 1, weights: { purge_events: 100 })
    traffic(workers: 20, qps: 500, weights: { read_event: 100 })
  }
}
```

`drain` is the lane that can draw the `until` query, so it's the lane the stage is waiting on. `traffic` carries no predicate, so it's background: it exists to measure the latency the purge causes.

When `drain` fires, the stage ends and `traffic` is cancelled with it. The point of the traffic was to measure the purge, and there's no purge left to measure.

With two draining lanes in one stage, the stage waits for **both**. The one that empties first stops; the other keeps going. A first-one-wins rule would cut the slower drain off mid-way.

`duration` stays a cap. A purge that never finishes - because something else keeps writing old rows - ends the stage no later than it would have ended anyway.

Without stages there's no lane to end, so a predicate that holds ends the run, capped by `--duration`.

## Writing the predicate

Bare, like `assert` and `rollback_if`:

```edg
until: affected() < 5000     # correct
until: "affected() < 5000"   # a string literal; fails to compile
```

`affected()` counts rows affected for an `exec` and rows returned for a `query`, so the same predicate works against a `DELETE ... RETURNING id`. It sums across the arg sets and batches one query expands into. Drivers that report no count give `-1`: Cassandra and Redis never do, and a transaction's statements are queued until commit.

## Transactions

Put both options on the transaction, not on a query inside it - the transaction is the unit that commits, and edg rejects the nested form. A transaction's `affected()` covers every statement it ran.

```edg
run {
  transaction drain(helper: true, until: affected() < 1000) {
    purge_events(type: exec) `DELETE FROM event WHERE id IN (SELECT id FROM event WHERE created_at < $1 LIMIT 1000)` (cutoff)
    purge_index(type: exec)  `DELETE FROM event_index WHERE event_id NOT IN (SELECT id FROM event)`
  }
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
--config examples/run_until/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
--tui \
--pause
```

The run seeds 500k events with timestamps spread across two years, so roughly half fall outside the 30-day retention window. The purge clears them 5000 at a time - about 50 iterations - and the stage ends there rather than at the hour it was given.
