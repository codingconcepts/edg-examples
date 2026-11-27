# libSQL / Turso

A basic libSQL example demonstrating table creation, batch inserts with `__values__`, cross-table references, and a read/write run loop.

libSQL is a fork of SQLite with a server in front of it, so the SQL here is identical to [the SQLite example](../sqlite/). What differs is the connection: the database is remote and every statement is an HTTP or WebSocket round trip, rather than a file opened in-process.

## Setup

Either run a local server:

```sh
docker compose -f infra/compose_libsql.yml up -d
```

```sh
until curl -sf http://127.0.0.1:8090/health > /dev/null; do
  echo "waiting for libsql..."; sleep 1
done && echo "libsql ready"
```

Or point at a Turso database, in which case no container is needed:

```sh
export URL="libsql://your-db-your-org.turso.io?authToken=$(turso db tokens create your-db)"
```

The commands below use the local server. Swap the `--url` value for `$URL` to run them against Turso instead.

Use `127.0.0.1` rather than `localhost`: Docker publishes the port on `::1` too, and that listener accepts the connection and then drops it, so a resolver preferring IPv6 never reaches the working listener.

The compose file publishes sqld's 8080 on host port 8090, because 8080 is too often already taken by something else.

## Run

```sh
edg all \
--driver libsql \
--config examples/libsql/libsql.edg \
--url "http://127.0.0.1:8090" \
-w 4 -d 10s
```

Or one phase at a time:

```sh
edg up \
--driver libsql \
--config examples/libsql/libsql.edg \
--url "http://127.0.0.1:8090"

edg seed \
--driver libsql \
--config examples/libsql/libsql.edg \
--url "http://127.0.0.1:8090"
```

Check data. There is no shell to open against a local server, so query it over the same HTTP API the driver uses:

```sh
curl -s http://127.0.0.1:8090/v2/pipeline \
--json '{"requests":[{"type":"execute","stmt":{"sql":"SELECT COUNT(*) FROM account"}},{"type":"close"}]}'
```

Against Turso, `turso db shell your-db "SELECT COUNT(*) FROM account"` does the same thing.

```sh
edg deseed \
--driver libsql \
--config examples/libsql/libsql.edg \
--url "http://127.0.0.1:8090"

edg down \
--driver libsql \
--config examples/libsql/libsql.edg \
--url "http://127.0.0.1:8090"

docker compose -f infra/compose_libsql.yml down
```

## Notes

**URL schemes.** `libsql://` (TLS, the Turso default), `https://`, `http://`, `wss://` and `ws://`. The auth token goes in the URL as `authToken`. The driver rejects query parameters it doesn't recognise, so SQLite's `_pragma=` settings must not be passed.

**Concurrency.** libSQL has SQLite's single writer, but the server queues concurrent writers rather than refusing them. A multi-worker write workload needs none of SQLite's WAL, `busy_timeout` or `_txlock` tuning and never sees `SQLITE_BUSY`; contention shows up as write latency instead.

**What you're measuring.** There is no local file, so each statement is a network round trip. Throughput against a remote Turso database measures the network as much as the database. Run the local server above when the engine is the thing under test.

**Local files.** A `file:` URL works under `--driver libsql`, but it just opens the embedded SQLite engine. Use `--driver sqlite` for that.
