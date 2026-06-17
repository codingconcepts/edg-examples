# Plugins

Use custom Go functions in edg workloads via the plugin system. This example uses the [edg-plugins](https://github.com/codingconcepts/edg-plugins) SDK to build a WASM plugin that provides `hello` and `dice` functions for seed and run queries.

### Build the plugin

From this directory:

```sh
GOOS=wasip1 GOARCH=wasm go build -buildmode=c-shared -o examples/plugins/greetings.wasm ./examples/plugins
```

### REPL example

```sh
edg repl \
  --plugin ./examples/plugins/greetings.wasm

>> dice(6)
3
>> hello('Rob')
Hello, Rob!
>> type an expression...
```

### Start CockroachDB

```sh
cockroach demo --insecure --no-example-database
```

### Run the workload

```sh
edg all \
  --driver pgx \
  --url "postgres://root@localhost:26257?sslmode=disable" \
  --config examples/plugins/crdb.edg \
  --plugin ./examples/plugins/greetings.wasm
```

### Verify

```sql
SELECT * FROM greetings LIMIT 5;
```

Each row will have a greeting like "Hello, John!" and a random d20 roll.
