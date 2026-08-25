# Identifiers

An event ingest workload keyed by `ulid()`, de-duplicated with `hash()`, and routed to shards by the same hash.

## Functions

| Function | Signature | Returns | Description |
|---|---|---|---|
| `ulid` | `ulid()` | `string` | 26-character Crockford base32 ID: 48-bit millisecond timestamp followed by 80 random bits |
| `hash` | `hash(value, algo)` | `string` | Deterministic unkeyed hex digest, `algo` is `md5`, `sha1`, `sha256` or `crc32` |

### Digest widths

| Algorithm | Hex characters |
|---|---|
| `crc32` | 8 |
| `md5` | 32 |
| `sha1` | 40 |
| `sha256` | 64 |

### `hash` vs `mask`

Both produce a hex digest, but they solve different problems:

| | `hash(value, algo)` | `mask(key, value)` |
|---|---|---|
| Keyed | No | Yes, HMAC with `key` |
| Stable across runs and machines | Yes | Only where the same key is used |
| Intended for | Dedup keys, shard selection, cache keys | Pseudonymising PII |

Because `hash()` takes no key, the same input always yields the same digest, which is exactly what a dedup key needs and exactly what a pseudonym should not be. See [Locale](../locale/) for `mask()`.

## What it demonstrates

- **`ulid()` as a primary key** - sortable by insertion time, so `ORDER BY id` is chronological and recent rows cluster together on write, unlike `uuid_v4()`.
- **`hash()` as a dedup key** - `ingest_replay` re-submits an email that is already in the table. Because `hash('...', 'sha256')` is deterministic, the digest matches the stored `dedup_key` and the `ON CONFLICT DO NOTHING` swallows the insert.
- **`hash()` as a shard key** - `scan_shard` regenerates the `crc32` digest of an email and scans the bucket its first hex character falls into, without needing the shard to be stored anywhere the client can read.
- **Regenerating a key instead of storing it** - `lookup_by_email` finds a row by `dedup_key` alone, computed from the email at query time.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Run

```sh
edg up \
--driver pgx \
--config examples/identifiers/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/identifiers/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/identifiers/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 4 \
-d 30s
```

### Check

Connect:

```sh
cockroach sql --insecure
```

ULIDs sort chronologically:

```sql
SELECT id, created_at
FROM event
ORDER BY id
LIMIT 5;
```

The `created_at` column should be ascending alongside `id`.

Digest widths per algorithm:

```sql
SELECT
  length(crc32) AS crc32,
  length(md5) AS md5,
  length(sha1) AS sha1,
  length(sha256) AS sha256
FROM digest;

  crc32 | md5 | sha1 | sha256
--------+-----+------+---------
      8 |  32 |   40 |     64
```

Shard distribution across the 16 buckets:

```sql
SELECT substr(shard_key, 1, 1) AS shard, count(*) AS total
FROM event
GROUP BY 1
ORDER BY 1;
```

Counts should be roughly even, because `crc32` spreads inputs uniformly.

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/identifiers/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/identifiers/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
