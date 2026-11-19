# Retries

Per-query and per-transaction retry policies. A `retries` option runs a statement again when it fails, overriding the global `--retries` flag for whatever carries it.

```edg
run {
  # Retry up to 5 times as fast as the database will take the attempts.
  credit_account(type: exec, retries: { max: 5 }) `UPDATE account SET balance = balance + $2::FLOAT
    WHERE id = $1::UUID` (
    ref('fetch_accounts').id,
    gen('number:1,100')
  )
}
```

| Field | Type | Default | Description |
|---|---|---|---|
| `max` | int | – | Attempts *after* the first, so `max: 2` runs the statement at most three times. Required. |
| `backoff` | duration | `0` | Delay before the first retry, doubling on each attempt after it. Zero retries as fast as possible. |
| `cap` | duration | – | Upper bound on the doubling. Requires `backoff`. |
| `args` | `reuse` \| `regenerate` | `reuse` | Whether a retry sends the same arguments again or generates fresh ones. |
| `on` | list of classes | `[retryable]` | Which classes of error the policy repeats. |

## What gets retried

By default, only errors that repeating could clear: serialization failures, deadlocks, lock timeouts, overloaded coordinators, request timeouts, and anything meaning the database was uncontactable. A unique violation, a failed check constraint or a syntax error fails on the first attempt however high `max` is.

A run that ends mid-backoff stops retrying rather than spending the drain window on attempts nobody is waiting for.

## Choosing what gets retried

`on` replaces that default with a list of classes. A failure is retried if any listed class matches, so listing more widens and listing one narrow class tightens.

| Class | What it matches |
|---|---|
| `retryable` | The default: contention, overload, request timeouts and unreachability. |
| `down` | Unreachability and timeouts only. A strict subset of `retryable`. |
| `constraint` | Rows the database refused: unique, foreign key, check, not-null. |
| `all` | Every error, including the ones no retry can clear. |

```edg
# Ride out an outage, but let contention show up as errors.
read_orders(retries: { max: 20, on: [down], backoff: 10ms, cap: 1s }) `SELECT * FROM account LIMIT 100`
```

Cancellation is never retried, including under `on: [all]` - a cancelled query means the run is ending.

`on: [constraint]` is usually worth pairing with `args: regenerate`, since a collision on a value the arguments supplied can only clear with a different value. It isn't a rule: a foreign key violation clears once a concurrent query commits the parent row, and a unique violation on a server-generated key never involved the arguments. `edg doctor` warns about the pairing when a query sends arguments, and stays quiet when it sends none.

## Backoff

`backoff` sets the first delay and doubles from there; `cap` stops the doubling. `{max: 10, backoff: 1ms, cap: 100ms}` waits 1, 2, 4, 8, 16, 32, 64, 100, 100, 100ms.

Leaving `backoff` out retries immediately, which suits brief contention and suits an already-struggling database much less.

## Fresh arguments

`args: regenerate` draws new arguments for every attempt, so a retry is not doomed to collide the same way the first attempt did. It costs another value from each sequence and uniqueness pool the query touches.

Pairing it with `on: [retryable, constraint]` is what lets the duplicate reference itself be retried, rather than only the contention around it:

```edg
write_ledger(type: exec, retries: { max: 5, on: [retryable, constraint], backoff: 1ms, cap: 100ms, args: regenerate }) `INSERT INTO ledger (reference, amount)
  VALUES ($1, $2::FLOAT)` (
  uniq("gen('uuid')"),
  gen('number:1,1000')
)
```

## Transactions

`retries` goes on the transaction, never on a statement inside it - edg rejects a config that tries. The first failing statement has already aborted the transaction, so retrying that one statement has nothing left to run in. Each attempt re-runs the transaction from `BEGIN`, re-evaluating its locals and arguments.

```edg
transaction transfer(retries: { max: 10, backoff: 1ms, cap: 500ms }) {
  ...
}
```

## Reporting

A query that retried and recovered reports one success, not a run of failures, so retries don't inflate the error count. The count appears as:

- a `RETRIES` column in the progress and summary tables, shown only once something has retried
- the `edg_query_retries_total` Prometheus counter
- the `retry_count` and `retry_rate` metrics in expectations and inline asserts

```edg
expect {
  low_errors  error_rate < 1
  low_retries retry_rate < 25
}
```

A workload only keeping up by retrying hard passes every other check, so gating on the retry rate catches what the error rate cannot.

Downtime is the exception. Every failed attempt reaches the availability trackers as it happens, so a workload retrying its way through a partition still reports itself down for as long as the partition lasts - rather than going quiet with `DOWNTIME` reading zero.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

```sh
edg all \
--driver pgx \
--config examples/retries/crdb.edg \
--url "postgres://root@localhost:26257/retries?sslmode=disable" \
-w 20 \
-d 1m
```
