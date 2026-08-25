# Redis

A Redis example demonstrating hash writes, a set used as an index, cursored `SCAN` reads via Lua, and weighted run queries.

Queries are Redis commands written the way you'd type them into `redis-cli`. Placeholders (`$1`, `$2`, ...) are inlined into the command text, so the same placeholder can appear more than once.

## Setup

```sh
docker compose -f infra/compose_redis.yml up -d
```

## Run

```sh
edg all \
--driver redis \
--config examples/redis/redis.edg \
--url "redis://localhost:6379" \
-w 4 -d 10s
```

Or one phase at a time:

```sh
edg up \
--driver redis \
--config examples/redis/redis.edg \
--url "redis://localhost:6379"

edg seed \
--driver redis \
--config examples/redis/redis.edg \
--url "redis://localhost:6379"
```

Check data:

```sh
docker exec redis redis-cli DBSIZE
docker exec redis redis-cli HGETALL customer:1
docker exec redis redis-cli SCARD customer:ids
```

```sh
edg deseed \
--driver redis \
--config examples/redis/redis.edg \
--url "redis://localhost:6379"

edg down \
--driver redis \
--config examples/redis/redis.edg \
--url "redis://localhost:6379"
```

## Notes

* **Replies become rows.** A hash is one row of fields, an array is one row per element under a `value` column, and a scalar is a single `value`. A missing key yields no rows rather than an error.
* **`init` reads use `SCAN`, not `KEYS`.** `KEYS` blocks the server for the length of the sweep. The Lua wrapper here walks the cursor and returns keys, so the run query reads `ref('fetch_customers').value`.
* **Numbers.** `uniform.int` returns a float, so wrap it in `int()` when the value has to be an integer Redis will accept (`HINCRBY`, `EXPIRE`, and so on).
* **Type inference.** No Redis command matches edg's SQL/Mongo verb inference, so commands default to `query`. Mark writes `type: exec` to skip reading a reply.
* **Batches and transactions.** `exec_batch` sends its commands in one non-transactional pipeline. A `transaction` block queues writes into `MULTI`/`EXEC` and flushes them on commit; reads run immediately, so a transaction can't read its own uncommitted writes.
