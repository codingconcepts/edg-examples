# LLM Batch Generation (complete_array)

Demonstrates `complete_array` for generating multiple structured items in a single LLM call. Instead of one API call per row, `complete_array` asks the model to return N items at once, and `ref_each()` iterates through the results.

## Function

| Function | Signature | Description |
|---|---|---|
| `complete_array` | `complete_array(tool_name, prompt, count)` | Generate N items in a single LLM call. Returns `[]map` for use with `ref_each()`. |

## How it works

1. `complete_array("review", prompt, 5)` sends one API request asking for 5 items
2. The tool schema is automatically wrapped in an `items` array
3. The model returns all 5 items in a single response
4. `ref_each(local("reviews"))` iterates through the array, one item per row

This is more efficient than `complete()` in a loop (1 API call vs N).

## Configuration

See [`_examples/complete/`](../_examples/complete/) for LLM client setup (API key, URL, model flags).

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d

# Env vars/
source .env

# Or if encrypted with dotenvx.
eval $(dotenvx get --format shell)
```

### Run

```sh
go run ./cmd/edg up \
--driver pgx \
--config _examples/complete_array/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

go run ./cmd/edg seed \
--driver pgx \
--config _examples/complete_array/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```

### Verify

```sh
cockroach sql --insecure
```

```sql
SELECT product_name, sentiment, rating, substring(review_text, 1, 60) AS review
FROM review
ORDER BY created_at DESC
LIMIT 10;
```

### Teardown

```sh
go run ./cmd/edg deseed \
--driver pgx \
--config _examples/complete_array/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

go run ./cmd/edg down \
--driver pgx \
--config _examples/complete_array/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```
