# Print

Demonstrates the `print` field on queries, which evaluates expressions each iteration and displays aggregated values in the progress and summary output.

Print entries can be a simple string (auto-aggregated) or a map with `expr` and `agg` fields for custom aggregation. Print expressions have access to the same context as query args: `ref_same`, `ref_rand`, `arg()`, `global()`, `local()`, and all built-in functions.

## Simple form (auto-aggregate)

A plain string auto-detects the value type: categorical values show frequency distributions, numeric values show min/avg/max.

```edg
print:
  - ref_same('regions').name
```

## Custom aggregation

Use the map form to write an `agg` expression that controls the output. The `agg` expression has access to these variables:

| Variable | Type | Description |
|---|---|---|
| `count` | int | Total observations |
| `freq` | map[string]int | Value frequency distribution |
| `min` | float | Minimum numeric value |
| `max` | float | Maximum numeric value |
| `avg` | float | Mean of numeric values |
| `sum` | float | Sum of numeric values |

All [expr-lang](https://expr-lang.org/docs/language-definition) functions are available in `agg` expressions (`toPairs`, `sortBy`, `join`, `map`, `string`, `int`, etc.).

### Examples

**Frequency distribution** - top 5 values sorted by count:

```edg
- expr: ref_same('regions').name
  agg: "join(map(sortBy(toPairs(freq), -#[1])[:5], #[0] + '=' + string(#[1])), ' ')"
# us=340 eu=330 ap=330
```

**Range with average** - formatted numeric summary:

```edg
- expr: arg(3)
  agg: "'avg $' + string(int(avg)) + ' n=' + string(count)"
# avg $250 n=1000
```

**Total count** - simple observation counter:

```edg
- expr: arg(0)
  agg: "string(count)"
# 1000
```

**Sum** - running total:

```edg
- expr: arg(3)
  agg: "'total=$' + string(int(sum))"
# total=$250317
```

**Min/max** - value bounds:

```edg
- expr: arg(3)
  agg: "string(int(min)) + ' - ' + string(int(max))"
# 1 - 499
```

**Unique count** - number of distinct values:

```edg
- expr: ref_same('regions').name
  agg: "string(len(freq)) + ' unique'"
# 3 unique
```

## Example output

```
PRINT         VALUES
insert_order  eu=1647 ap=1604 us=1585
insert_order  min=248.87 avg=1.01 max=499.93 n=4836
insert_order  paris=552 london=548 berlin=547 sydney=542 tokyo=535
insert_order  avg $248 n=4836
insert_order  total=$1203541
insert_order  1 - 499
insert_order  9 unique
read_order    us=1699 eu=1602 ap=1531
read_order    4832
```

> [!NOTE]
> Print expressions using `ref_same` see the same row selected for the query args in that iteration, so `ref_same('regions').name` in `print` matches `ref_same('regions').name` in `args`.

## Post print (query results)

The `post_print` field works like `print` but evaluates **after** the query executes. Use `result()` to access the first row of a `type: query` SELECT result:

```edg
- name: read_order
  type: query
  args:
    - ref_same('regions').name
  query: |-
    SELECT id, amount FROM print_order WHERE region = $1 LIMIT 1
  post_print:
    - expr: result().amount
      agg: "string(int(min)) + '..' + string(int(max)) + ' avg=' + string(int(avg))"
```

Both `print` and `post_print` can be used on the same query - `print` for input distributions (args, refs), `post_print` for output observations (SELECT results).

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
--config examples/print/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 10s
```
