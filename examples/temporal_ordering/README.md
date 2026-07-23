# Temporal Ordering

Ensures child rows have timestamps strictly after their parent rows using `after()` with `ref_same()`.

In this example, every shipment's `shipped_at` is guaranteed to be between 2 hours and 72 hours after its order's `created_at`.

## Key expressions

```edg
# Parent: random timestamp in 2024
timestamp('2024-01-01T00:00:00Z', '2024-12-31T00:00:00Z')

# Child: 2h to 72h after the same parent row's created_at
after(ref_same('populate_orders').created_at, '2h', '72h')
```

`ref_same()` ensures the `order_id` and `created_at` come from the same parent row. `after()` generates a random timestamp in `[base + min_offset, base + max_offset]`.

A symmetric `before()` function is also available for the inverse pattern.

## Running

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Run

```sh
edg up \
--driver pgx \
--config examples/temporal_ordering/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/temporal_ordering/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```

### Check

Connect:

```sh
cockroach sql --insecure
```

Verify every shipment was shipped after its order was created:

```sql
SELECT
  o.created_at AS order_created,
  s.shipped_at AS shipment_shipped,
  s.shipped_at - o.created_at AS lag
FROM shipments s
JOIN orders o ON o.id = s.order_id
ORDER BY lag
LIMIT 20;
```

All `lag` values should be between 2 hours and 72 hours.

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/temporal_ordering/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/temporal_ordering/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
