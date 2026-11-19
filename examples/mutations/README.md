# Mutations

An example of injecting controlled data-quality bugs with the `mutate` section, to prove a schema's constraints are actually enforced.

The schema puts a constraint on every column the workload writes - `NOT NULL`, `UNIQUE`, a foreign key and a `CHECK` - and the `mutate` block aims one bug at each:

```edg
mutate {
  # NOT NULL and the foreign key on account.
  open_account.customer_id { fk_break(count: 3) }

  # CHECK (balance >= 0).
  open_account.balance { range(count: 3) }

  # NOT NULL and UNIQUE on customer.email.
  add_customer.email {
    null(count: 3)
    dup(count: 3)
  }
}
```

Every mutation reports its own verdict after the run, and edg exits non-zero if any of them failed - no `expect` block needed:

```
mutations
  v open_account.customer_id.fk_break  3 applied, 3 rejected (foreign_key_violation)
  v open_account.balance.range         3 applied, 3 rejected (check_violation)
  v add_customer.email.null            3 applied, 3 rejected (not_null_violation)
  v add_customer.email.dup             3 applied, 3 rejected (unique_violation)
```

## Seeing it fail

The point of the feature is the run where a constraint *isn't* there. Drop SQLite's foreign-key enforcement and the FK probe stops bouncing:

```sh
# ...&_pragma=foreign_keys(0)
  x open_account.customer_id.fk_break  3 applied, 3 accepted - no foreign_key_violation is enforcing this
```

The run exits 1. That is the same signal you would get from a migration that quietly dropped a constraint, which is otherwise close to invisible.

## Notes

* Mutations apply to **run queries only**. A seed is usually batched, and one bad row fails the whole batch, so edg rejects a mutation aimed at a batched query.
* Each kind only applies where it means something: `fk_break` needs a `ref()` column, `dup` needs a `uniq()` column. Aiming one at a column it cannot act on is a config error rather than a silent skip.
* At most one mutation acts on any row, so each probe tests exactly one constraint.
* `count` fires an exact number of probes; `rate` affects a share of operations, which suits soak runs.
* For an unconstrained target - an ELT landing table, a warehouse where foreign keys are advisory - set `expect: pass` and the bad row landing becomes the success case, for a downstream validator to catch.

## Ad-hoc and random mutations

Mutations can also come from flags, which replace the config's block for that run:

```sh
edg run --config examples/mutations/sqlite.edg --mutate 'null:add_customer.email,count=3'
edg run --config examples/mutations/sqlite.edg --mutate-random 3 --rng-seed 42
edg run --config examples/mutations/sqlite.edg --no-mutate
```

## SQLite

SQLite is embedded, so there's no container to start. Note `foreign_keys(1)`: SQLite does not enforce foreign keys unless you ask it to, so without that pragma the `fk_break` probe correctly reports the constraint as missing.

### Run

```sh
edg all \
--driver sqlite \
--config examples/mutations/sqlite.edg \
--url "file:edg.db?_pragma=foreign_keys(1)&_pragma=busy_timeout(5000)&_txlock=immediate" \
--pool-size 1 \
-w 1 -d 10s
```

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Run

```sh
edg all \
--driver pgx \
--config examples/mutations/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 4 -d 10s
```
