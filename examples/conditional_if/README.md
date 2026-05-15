# Conditional If

Demonstrates `if/then/else` branching for binary conditions using customer markets to dispatch region-specific logic.

**Standalone** (outside a transaction) - reads a random customer and logs a GDPR compliance check only for UK-market customers:

```yaml
- if: "ref_same('read_customer').market == 'uk'"
  then:
    - name: log_gdpr_check
      type: exec
      args:
        - ref_same('read_customer').id
        - ref_same('read_customer').market
      query: |-
        INSERT INTO compliance_log (customer_id, market, check_type)
        VALUES ($1::UUID, $2::STRING, 'gdpr_data_access')
  else:
    - noop
```

**Inside a transaction** - places an order with market-specific tax and currency. UK customers pay 20% VAT in GBP; all others pay 10% tax in USD:

```yaml
- if: "ref_same('read_buyer').market == 'uk'"
  then:
    - name: insert_uk_order
      type: exec
      args:
        - ref_same('read_buyer').id
        - ref_same('read_product').id
        - ref_same('read_product').price
        - ref_same('read_product').price * 0.20
        - ref_same('read_buyer').market
      query: |-
        INSERT INTO order_log (customer_id, product_id, subtotal, tax, currency, market)
        VALUES ($1::UUID, $2::UUID, $3::FLOAT, $4::FLOAT, 'GBP', $5::STRING)
  else:
    - name: insert_other_order
      type: exec
      args:
        - ref_same('read_buyer').id
        - ref_same('read_product').id
        - ref_same('read_product').price
        - ref_same('read_product').price * 0.10
        - ref_same('read_buyer').market
      query: |-
        INSERT INTO order_log (customer_id, product_id, subtotal, tax, currency, market)
        VALUES ($1::UUID, $2::UUID, $3::FLOAT, $4::FLOAT, 'USD', $5::STRING)
```

> [!NOTE]
> Standalone `if` blocks cannot be used with `run_weights` (top-level or via `stages`).

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

##### Automatic verification (via expectations)

Run

```sh
edg all \
--driver pgx \
--config examples/conditional_if/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 4 -d 10s
```

##### Manual verification

Run

```sh
edg up \
--driver pgx \
--config examples/conditional_if/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/conditional_if/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/conditional_if/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 4 -d 10s
```

Verify

```sql
-- `then` branch correct - every compliance log is for a UK customer.
-- Expected: 0
SELECT COUNT(*) AS violations FROM compliance_log WHERE market != 'uk';

-- `else` branch correct - no non-UK customer has a compliance entry.
-- Expected: 0
SELECT COUNT(*) AS non_uk_compliance
FROM compliance_log cl
JOIN customer c ON c.id = cl.customer_id
WHERE c.market != 'uk';

-- Currency matches market - UK orders use GBP, all others use USD.
-- Expected: 0
SELECT COUNT(*) AS currency_mismatches
FROM order_log
WHERE (market = 'uk' AND currency != 'GBP')
   OR (market != 'uk' AND currency != 'USD');

-- Tax rates correct - UK orders have 20% VAT, others have 10% tax.
-- Expected: 0
SELECT COUNT(*) AS tax_mismatches
FROM order_log
WHERE (currency = 'GBP' AND abs(tax - subtotal * 0.20) > 0.01)
   OR (currency = 'USD' AND abs(tax - subtotal * 0.10) > 0.01);

-- Both branches exercised - orders exist for both UK and non-UK customers.
-- Expected: rows for both GBP and USD
SELECT currency, COUNT(*) AS orders FROM order_log GROUP BY currency ORDER BY currency;
```

Teardown

```sh
edg deseed \
--driver pgx \
--config examples/conditional_if/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/conditional_if/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```
