# Remote Config

Load a workload config from a URL instead of a local file.

The `--config` flag (and `EDG_CONFIG` env var) accepts HTTP and HTTPS URLs. edg fetches the YAML and runs it the same as a local file.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Serve a local config over HTTP

```sh
python3 -m http.server 8000 -d _examples/tpcc

# Terminal 2: run edg against it
go run ./cmd/edg all \
--driver pgx \
--config "http://localhost:8000/crdb.yaml" \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 1 \
-d 10s
```

## Limitations

- `!include` directives are not resolved for remote configs (no local filesystem to resolve relative paths against).
