# cursor

This example demonstrates `ref_cursor` for keyset-paginated iteration over large tables. Instead of loading all customer IDs into memory (like `ref_each`), `ref_cursor` pages through results using `WHERE id > $last ORDER BY id LIMIT $size`, keeping constant memory usage regardless of table size.

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
--config examples/cursor/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/cursor/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

# Verify: should show 10000 accounts (one per customer).
cockroach sql --insecure -e "SELECT account_count, COUNT(*) AS num_customers
FROM (
  SELECT customer_id, COUNT(*) AS account_count
  FROM account
  GROUP BY customer_id
)
GROUP BY account_count
ORDER BY account_count"

edg deseed \
--driver pgx \
--config examples/cursor/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/cursor/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```
