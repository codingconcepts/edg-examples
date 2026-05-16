# Jobs

Run edg as an HTTP server and submit workloads via CLI or API.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Start the server (without token)

```sh
edg jobs serve
```

### Submit a workload

```sh
response=$(edg jobs submit \
  --url "postgres://root@localhost:26257?sslmode=disable" \
  --driver pgx \
  --config examples/serve/crdb.yaml \
  --duration 1h \
  --workers 1)

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

### Cancel a running job

```sh
edg jobs cancel ${job_id}
```

### Health check

```sh
edg jobs health
```

### Start the server (with token)

```sh
edg jobs serve --token my-secret-token
```

When a token is set, all requests to job endpoints must include the `Edg-Jobs-Token` header. The `/healthz` endpoint remains unauthenticated.

```sh
response=$(edg jobs submit \
  --url "postgres://root@localhost:26257?sslmode=disable" \
  --driver pgx \
  --config examples/serve/crdb.yaml \
  --duration 1h \
  --workers 1 \
  --token my-secret-token)

job_id=$(echo ${response} | jq -r .id)
```

```sh
edg jobs status --token my-secret-token
```

```sh
edg jobs stream ${job_id} --token my-secret-token
```

```sh
edg jobs cancel ${job_id} --token my-secret-token
```

### Teardown

```sh
docker compose -f infra/compose_crdb.yml down -v
```
