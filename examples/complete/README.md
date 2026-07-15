# LLM Text Generation

Demonstrates `complete` and `complete_array` for structured text generation via an LLM with tool calling. The LLM is forced to return structured data matching a tool schema defined in the config, and individual fields are accessed via dot notation.

## Functions

| Function | Signature | Description |
|---|---|---|
| `complete` | `complete(tool_name, prompt).field` | Call LLM with tool schema, returns structured map. Access fields with dot notation. |
| `complete_array` | `complete_array(tool_name, prompt, count)` | Generate N items in a single LLM call, returns `[]map`. Use with `ref_each()` to iterate. |

## Configuration

The LLM client needs an API key and optionally a custom URL and model:

| Flag | Env Var | Default |
|---|---|---|
| `--complete-api-key` | `EDG_COMPLETE_API_KEY` | *(required)* |
| `--complete-url` | `EDG_COMPLETE_URL` | `https://api.openai.com/v1/chat/completions` |
| `--complete-model` | `EDG_COMPLETE_MODEL` | `gpt-4o` |

Any OpenAI-compatible API works (Ollama, vLLM, Azure OpenAI, etc.) - set `--complete-url` to point at your endpoint.

## Tool Schema

Tools are defined in the `complete` section. Each tool has a name, system prompt, and JSON Schema properties:

```edg
complete:
  tools:
    - name: review
      system: "Generate realistic product reviews."
      properties:
        review_text:
          type: string
          description: "A 2-3 sentence product review"
        sentiment:
          type: string
          enum: [positive, negative, neutral]
        rating:
          type: integer
          description: "Star rating from 1 to 5"
      required: [review_text, sentiment, rating]
```

## Execution Modes

### Using with locals

Use `locals` to call `complete()` once and access multiple fields:

```edg
locals:
  review: 'complete("review", prompt)'
args:
  - local("review").review_text
  - local("review").sentiment
  - local("review").rating
```

### Immediate mode (single-row queries)

For `exec`/`query` types, `complete()` calls the API directly. Locals are evaluated once per row.

### Deferred mode (batch queries)

For `exec_batch`/`query_batch` types, all `complete()` calls are collected as placeholders during row evaluation, then resolved concurrently (up to 8 parallel requests) after all rows are generated. Placeholders are replaced in the formatted SQL before execution.

> [!NOTE]
> In deferred mode, complete field values are substituted as strings in the SQL. Use casts for non-string types: `g::INT` for integers, `g::FLOAT` for floats.

### Array mode (complete_array)

`complete_array` generates N items in a single API call. The tool schema is automatically wrapped in an array request. Use `ref_each()` to iterate through the results:

```edg
locals:
  reviews: 'complete_array("review", "Generate 5 product reviews", 5)'
args:
  - ref_each(local("reviews")).review_text
  - ref_each(local("reviews")).sentiment
  - ref_each(local("reviews")).rating
```

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure

# Env vars
source .env # Or similar...
```

### Run

```sh
edg up \
--driver pgx \
--config examples/complete/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/complete/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/complete/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 1 \
-d 10s
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
edg deseed \
--driver pgx \
--config examples/complete/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/complete/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```

## Using with Ollama

```sh
edg up \
  --driver pgx \
  --config examples/complete/crdb.edg \
  --url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
  --driver pgx \
  --config examples/complete/crdb.edg \
  --url "postgres://root@localhost:26257?sslmode=disable" \
  --complete-api-key ollama \
  --complete-url http://localhost:11434/v1/chat/completions \
  --complete-model qwen3:8b
```

> [!NOTE]
> Tool calling support varies by model. Use models that support OpenAI-compatible tool calling (llama3.1+, mistral, etc.).
