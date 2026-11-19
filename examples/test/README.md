# Test driver

The `test` driver is an in-memory key/value cache rather than a database, so this example runs with nothing installed and no `--url`. Use it to check that a config *runs* - the generators fire, the refs resolve, the transactions commit and roll back - without standing up a server.

It speaks six commands:

| Command | Meaning |
|---|---|
| `CREATE <map>` | Creates a named map. Idempotent, and keeps existing data. |
| `DROP <map>` | Removes the map and everything in it. Dropping a missing map isn't an error. |
| `SET <map> <key> <value>...` | Writes one key. Several values are joined with a space. |
| `GET <map> <key>` | One row under the `value` column, or no rows when the key is missing. |
| `DEL <map> <key>` | Deletes one key exactly. A missing key isn't an error. |
| `DEL <map> <prefix>*` | Deletes every key under the prefix. A trailing `*` is the only wildcard; `DEL <map> *` empties the map. |
| `LIST <map> [<prefix>*]` | One row per matching key, sorted. The keys are bare - the map is named separately. |

Reading or writing a map that was never `CREATE`d is an error, so a config that forgets its `up` section fails loudly rather than silently doing nothing.

## Setup

None.

## Run

```sh
edg all \
--driver test \
--config examples/test/test.edg \
-w 4 -d 10s
```

The cache lives for the life of the process, so `edg all` and `edg run` work but running phases separately does not - each invocation starts empty:

```sh
# This seeds a cache that is thrown away the moment the command exits.
edg seed --driver test --config examples/test/test.edg

# ...so this one finds nothing to read.
edg run --driver test --config examples/test/test.edg
```

## Notes

* **No URL.** `--driver test` needs none, and ignores one if given.
* **Maps, not tables.** There is no schema. Each table becomes a named map, created in `up` and dropped in `down`.
* **`DEL` empties, `DROP` removes.** `DEL customer *` clears the map but leaves it usable, which is what `deseed` wants. `DROP customer` removes it, so `up` has to run again.
* **Flat values.** A map holds strings, not records, so a multi-column row is space-joined into one value and `GET` returns the whole row. Column boundaries aren't recoverable - if you need fields back out, use `--driver redis` and `HSET`/`HGETALL`.
* **Don't quote a batch group.** `SET m $1 $2 $3` expands to one write per row; `SET m $1 "$2 $3"` does not, because batch expansion skips anything inside quotes and every row ends up with the same separator-laden value. Pass the columns as separate arguments and let `SET` join them.
* **Replies become rows.** `GET` is a single `value`; `LIST` is one row per key under `value`, sorted so a run is reproducible. A missing key yields no rows rather than an error, but a missing *map* is an error.
* **Type inference.** As with Redis, no command matches edg's SQL/Mongo verb inference, so commands default to `query`. Mark writes `type: exec` to skip reading a reply.
* **Transactions read their own writes.** Writes apply immediately and are reversed from an undo log on rollback, so the `confirm` read in the transaction sees the `overwrite` above it and `rollback_if` genuinely undoes it. Redis can't do this - `MULTI` queues writes until `EXEC`.
* **Transactions serialise.** One runs at a time, which keeps rollback correct under many workers. A transactional workload therefore measures the lock, not the work.
* **Not a benchmark.** Throughput against an in-memory map is meaningless whichever way you cut it. Read the `ERRORS` column, not the `QPS` one.
