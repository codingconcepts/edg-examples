# Real Embeddings

Demonstrates `embed` for generating real vector embeddings via an external API (OpenAI-compatible). Unlike `vector`/`vector_zipf`/`vector_norm` which produce synthetic clustered vectors, `embed` calls a live embedding model so that similarity search reflects actual semantic relationships.

## Function

| Function | Signature | Description |
|---|---|---|
| `embed` | `embed(text...)` | Variadic - joins args with space, calls embedding API, returns pgvector literal. |

## Configuration

The embedding client needs an API key and optionally a custom URL, model, and dimensions:

| Flag | Env Var | Default |
|---|---|---|
| `--embed-api-key` | `EDG_EMBED_API_KEY` | *(required)* |
| `--embed-url` | `EDG_EMBED_URL` | `https://api.openai.com/v1/embeddings` |
| `--embed-model` | `EDG_EMBED_MODEL` | `text-embedding-3-small` |
| `--embed-dimensions` | `EDG_EMBED_DIMENSIONS` | `1536` |
| `--embed-max-batch` | `EDG_EMBED_MAX_BATCH` | `0` (unlimited) |

Any OpenAI-compatible API works (Ollama, vLLM, Azure OpenAI, etc.) - set `--embed-url` to point at your endpoint.

For batch queries (`exec_batch`/`query_batch`), all `embed()` calls within a batch are collected and resolved in a single API call. Use `--embed-max-batch` to cap texts per API call - e.g. `--embed-max-batch 30` on a 100-row batch produces 4 API calls (30, 30, 30, 10).

## Embedder

Export env vars for embedding models (I'm using DS1 Fukuro).

```sh
export EDG_EMBED_API_KEY="..."
export EDG_EMBED_URL="https://infer.dev.takara.ai/v1/embeddings"
export EDG_EMBED_MODEL="ds1-fukuro"
export EDG_EMBED_DIMENSIONS="512"
export EDG_EMBED_MAX_BATCH="32"
```

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

```sh
go run ./cmd/edg up \
--driver pgx \
--config _examples/embed/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

go run ./cmd/edg seed \
--driver pgx \
--config _examples/embed/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

go run ./cmd/edg run \
--driver pgx \
--config _examples/embed/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 4 \
-d 30s
```

### Verify similarity search

Connect

```sh
cockroach sql --insecure
```

```sql
WITH target AS (
  SELECT embedding
  FROM product
  ORDER BY random()
  LIMIT 1
)
SELECT p.name, p.embedding <=> t.embedding AS distance
FROM product p, target t
ORDER BY p.embedding <=> t.embedding
LIMIT 5;
```

### Teardown

```sh
go run ./cmd/edg deseed \
--driver pgx \
--config _examples/embed/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

go run ./cmd/edg down \
--driver pgx \
--config _examples/embed/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```

## Using with Ollama

```sh
go run ./cmd/edg seed \
--driver pgx \
--config _examples/embed/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
--embed-api-key ollama \
--embed-url http://localhost:11434/v1/embeddings \
--embed-model nomic-embed-text \
--embed-dimensions 768
```

> [!NOTE]
> When changing `--embed-dimensions`, update the `VECTOR(1536)` column type in the YAML to match.
