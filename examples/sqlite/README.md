# SQLite

A basic SQLite example demonstrating table creation, batch inserts with `__values__`, cross-table references, and a read/write run loop.

SQLite is embedded, so there's no container to start; the database is a file created on first connect.

## Concurrency

SQLite allows one writer at a time. edg passes the connection URL to the driver unchanged, so pragmas are yours to set:

* `journal_mode(WAL)` lets readers run alongside the writer.
* `busy_timeout(5000)` makes a blocked writer wait up to 5s for the lock instead of failing with `database is locked (5) (SQLITE_BUSY)`.

Without both, a multi-worker write workload will error. Alternatively, run with `--pool-size 1` to serialise every statement through a single connection.

## Run

```sh
edg all \
--driver sqlite \
--config examples/sqlite/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate" \
-w 4 -d 10s
```

Or one phase at a time:

```sh
edg up \
--driver sqlite \
--config examples/sqlite/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg seed \
--driver sqlite \
--config examples/sqlite/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"
```

Check data:

```sh
sqlite3 edg.db "SELECT COUNT(*) FROM customer; SELECT COUNT(*) FROM account;"
sqlite3 edg.db "SELECT * FROM account LIMIT 5;"
```

```sh
edg deseed \
--driver sqlite \
--config examples/sqlite/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

edg down \
--driver sqlite \
--config examples/sqlite/sqlite.edg \
--url "file:edg.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_txlock=immediate"

rm -f edg.db edg.db-wal edg.db-shm
```

## Notes

SQLite has no `UUID()`, `RAND()`, `NOW()`, or `TRUNCATE`. The equivalents used here are:

| Other SQL | SQLite |
|---|---|
| `UUID()` | `lower(hex(randomblob(16)))` |
| `RAND()` | `abs(random()) % 1000000 / 1000000.0` |
| `FLOOR(RAND() * N)` | `abs(random()) % N` |
| `NOW()` | `datetime('now')` |
| `TRUNCATE TABLE t` | `DELETE FROM t` |
