# Conditional Match

Demonstrates `match/when/default` branching for multi-way dispatch using customer markets to apply region-specific compliance checks and tax rules.

**Standalone** (outside a transaction) - reads a random customer and logs a region-specific compliance check: GDPR for UK, CCPA for US, standard for everyone else:

```yaml
- match: "ref_same('read_customer').market"
  when:
    - eq: "'uk'"
      queries:
        - name: log_gdpr
          type: exec
          args:
            - ref_same('read_customer').id
            - ref_same('read_customer').market
          query: |-
            INSERT INTO compliance_log (customer_id, market, check_type)
            VALUES ($1::UUID, $2::STRING, 'gdpr')
    - eq: "'us'"
      queries:
        - name: log_ccpa
          type: exec
          args:
            - ref_same('read_customer').id
            - ref_same('read_customer').market
          query: |-
            INSERT INTO compliance_log (customer_id, market, check_type)
            VALUES ($1::UUID, $2::STRING, 'ccpa')
  default:
    - name: log_standard
      type: exec
      args:
        - ref_same('read_customer').id
        - ref_same('read_customer').market
      query: |-
        INSERT INTO compliance_log (customer_id, market, check_type)
        VALUES ($1::UUID, $2::STRING, 'standard')
```

**Inside a transaction** - places an order with market-specific tax and currency. UK: 20% VAT in GBP, US: 10% sales tax in USD, EU (default): 23% VAT in EUR:

```yaml
- match: "ref_same('read_buyer').market"
  when:
    - eq: "'uk'"
      queries:
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
    - eq: "'us'"
      queries:
        - name: insert_us_order
          ...
  default:
    - name: insert_eu_order
      ...
```

The match expression is evaluated once and compared to each `eq` value. First match wins. The `default` block is optional - if no match and no default, the block is skipped.

> [!NOTE]
> Standalone `match` blocks cannot be used with `run_weights` (top-level or via `stages`).

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

##### Automatic verification (via expectations)

Run

```sh
go run ./cmd/edg all \
--driver pgx \
--config _examples/conditional_match/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 4 -d 10s
```

##### Manual verification

Run

```sh
go run ./cmd/edg up \
--driver pgx \
--config _examples/conditional_match/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

go run ./cmd/edg seed \
--driver pgx \
--config _examples/conditional_match/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

go run ./cmd/edg run \
--driver pgx \
--config _examples/conditional_match/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 4 -d 10s
```

Verify

```sql
-- All branches fired - each compliance check type appears.
-- Expected: rows for 'ccpa', 'gdpr', and 'standard'
SELECT check_type, COUNT(*) AS entries
FROM compliance_log
GROUP BY check_type
ORDER BY check_type;

-- Correct branch dispatched - every check_type matches the customer's market.
-- Expected: 0
SELECT COUNT(*) AS mismatches
FROM compliance_log cl
JOIN customer c ON c.id = cl.customer_id
WHERE (cl.check_type = 'gdpr'     AND c.market != 'uk')
   OR (cl.check_type = 'ccpa'     AND c.market != 'us')
   OR (cl.check_type = 'standard' AND c.market != 'eu');

-- Currency matches market - UK=GBP, US=USD, EU=EUR.
-- Expected: 0
SELECT COUNT(*) AS currency_mismatches
FROM order_log
WHERE (market = 'uk' AND currency != 'GBP')
   OR (market = 'us' AND currency != 'USD')
   OR (market = 'eu' AND currency != 'EUR');

-- Tax rates correct - UK=20%, US=10%, EU=23%.
-- Expected: 0
SELECT COUNT(*) AS tax_mismatches
FROM order_log
WHERE (currency = 'GBP' AND abs(tax - subtotal * 0.20) > 0.01)
   OR (currency = 'USD' AND abs(tax - subtotal * 0.10) > 0.01)
   OR (currency = 'EUR' AND abs(tax - subtotal * 0.23) > 0.01);

-- Every market exercised - all three markets have orders.
-- Expected: rows for eu/EUR, uk/GBP, and us/USD
SELECT market, currency, COUNT(*) AS orders
FROM order_log
GROUP BY market, currency
ORDER BY market;
```

Teardown

```sh
go run ./cmd/edg deseed \
--driver pgx \
--config _examples/conditional_match/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

go run ./cmd/edg down \
--driver pgx \
--config _examples/conditional_match/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```
