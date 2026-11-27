# Vector Recall

Measures how much of the exact nearest-neighbour answer an approximate vector index actually returns, and fails the run when it drops below a floor.

A vector index trades accuracy for speed. The accuracy half of that trade is invisible in a latency chart - a badly tuned index is fast precisely because it's skipping the answer. This example makes it visible.

## Functions

| Function | Signature | Description |
|---|---|---|
| `knn` | `knn(data, field, query, k)` | Brute-force k nearest neighbours over an already-loaded dataset. The exact ground truth. |
| `recall` | `recall(truth, got, field)` | Share of the ground-truth rows the approximate search found, in `[0, 1]`. |
| `vector` | `vector(dims, clusters, spread)` | Clustered unit-length vector literal, so there's something meaningful to search for. |

## How it works

1. `seed` fills `article` with 10,000 clustered vectors from `vector(32, 5, 0.1)`.
2. `init` loads every `(id, embedding)` into the `all_articles` dataset.
3. Each `run` iteration binds one query vector to the local `q`, searches through the index, then asserts:

```edg
search(type: query, assert: recall(knn('all_articles', 'embedding', local('q'), k), results(), 'id') >= 0.8)
  `SELECT id
   FROM article
   ORDER BY embedding <=> $1::VECTOR
   LIMIT 10`
  let q = vector(dims, 5, 0.1)
  (local('q'))
```

`knn` computes the exact top-k for the same `local('q')` the index just searched with, and `results()` hands `recall` the rows the index returned. Below `0.8` the run stops and prints the expression with the values that made it false.

## Why brute force in Go

The obvious alternative is to ask the database for the exact answer by turning the index off (`SET LOCAL enable_indexscan = off`). That hint is PostgreSQL-specific, needs session state a pool may not preserve, and a planner is free to ignore it.

`knn` scans rows already in memory instead, so it behaves identically on every driver and can't be outvoted by a query planner. The cost is that the corpus has to fit in memory - size the `init` query for the measurement, not for the workload. A `LIMIT`ed sample of 10,000 rows measures recall perfectly well.

## Metrics

`knn` defaults to cosine distance, matching pgvector's `<=>`. Pass a fifth argument for `l2` (`<->`) or `ip` (`<#>`):

```edg
knn('all_articles', 'embedding', local('q'), k, 'l2')
```

The metric has to match the one the index was built with. Measuring a cosine index against L2 ground truth reports a problem that doesn't exist. Vectors from `vector` are unit length, and for unit vectors cosine and L2 rank identically - the distinction starts to matter with real embeddings from `embed`.

## Tuning the knobs

| Change | Effect on recall |
|---|---|
| Lower `spread` (0.05) | Tighter, better-separated clusters - recall goes up |
| Higher `spread` (0.3+) | Overlapping clusters - the index has a harder time, recall drops |
| More rows | More candidates to miss, so recall usually drops |
| Higher `k` | Harder to find every one of the true top-k |

Start with the assert at `>= 0.8` and tighten it once you know what the index actually delivers. Recall below `1.0` isn't a fault - it's the trade you opted into. Assert the floor your application can live with.

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
--config examples/vector_recall/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 4 \
-d 30s
```

### Watch recall instead of gating on it

Swap the `assert` for a `post_print` to chart recall over the run rather than failing on it:

```edg
search(type: query, post_print: {key: "recall", value: recall(knn('all_articles', 'embedding', local('q'), k), results(), 'id')})
```

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/vector_recall/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/vector_recall/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```

## See also

- [`vector`](../vector) - the clustered vector generators and their distributions.
- [`embed`](../embed) - real embeddings from a live model, when synthetic clusters aren't enough.
