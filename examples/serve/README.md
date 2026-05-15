# Jobs

Run edg as an HTTP server and submit workloads via CLI or API.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Start the server

```sh
edg jobs serve
```

### Submit a workload

```sh
response=$(edg jobs submit \
  --url "postgres://root@localhost:26257?sslmode=disable" \
  --driver pgx \
  --config examples/serve/crdb.yaml \
  --duration 10s \
  --workers 4)

job_id=$(echo ${response} | jq -r .id)
```

### Stream logs

Stream separately using the returned job ID:

```sh
edg jobs stream ${job_id}
```

Or stream automatically by adding `--stream` to submit:

```sh
edg jobs submit \
  --url "postgres://root@localhost:26257?sslmode=disable" \
  --driver pgx \
  --config examples/serve/crdb.yaml \
  --duration 10s \
  --workers 4 \
  --stream \
  -o
```

### Check job status

```sh
edg jobs status
```

### Health check

```sh
edg jobs health
```

### Teardown

```sh
docker compose -f infra/compose_crdb.yml down -v
```
