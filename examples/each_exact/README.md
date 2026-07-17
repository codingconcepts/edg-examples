# each_exact

Demonstrates exact cardinality using `ref_each(dataset, N)` to guarantee every parent row gets exactly N children.

Each customer gets exactly `orders_per_customer` orders. The repeat count is passed as the second argument to `ref_each`, and `count` is set to `count('populate_customers') * orders_per_customer`.

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
--config examples/each_exact/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/each_exact/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

# Verify exact cardinality: every customer should have exactly 3 orders.
cockroach sql --insecure -e "
  SELECT c.name, COUNT(o.id) AS order_count
  FROM customer c
  JOIN orders o ON o.customer_id = c.id
  GROUP BY c.name
  ORDER BY c.name"

edg deseed \
--driver pgx \
--config examples/each_exact/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/each_exact/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
