# Tree (database-generated ids)

Declarative tree generation with the `tree` block, where the ids come from the database rather than from edg.

Most tree examples generate ids client-side with `seq_global`, so edg already knows every id before it writes a row and can wire each level to the one above from what it generated. Here `employees.id` is `UUID PRIMARY KEY DEFAULT gen_random_uuid()`, so only the database knows the ids.

`type: query` is what makes that work. It tells edg to keep the rows each level returns, so `manager_id` at level N can reference real ids from level N-1:

```edg
tree org(levels: [1, 5, 15, 50], id_column: id, parent_column: manager_id, type: query, size: 10)
  `INSERT INTO employees (name, title, manager_id)
   __values__
   RETURNING id` (
  ...
)
```

The `RETURNING id` clause is yours to write — edg never parses the SQL to check for one, because every driver spells it differently (`RETURNING` here, `OUTPUT INSERTED` on SQL Server, no equivalent on MySQL). edg checks the rows that come back instead: a level that returns nothing, or returns rows without `id` in them, fails at that level rather than one level later.

Levels span several batches (`size: 10` against 50 rows at the deepest level), and every id returned across every batch is available as a parent, not just the last batch's.

This produces 71 rows across 4 levels:

| Level | Count | Title |
|---|---|---|
| 0 | 1 | CEO |
| 1 | 5 | VP |
| 2 | 15 | Director |
| 3 | 50 | Manager |

> [!NOTE]
> `type: query` levels run on a single worker, since reading rows back rules out the parallel batch path. Trees with client-generated ids keep full batch parallelism.

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
--config examples/tree_returning/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/tree_returning/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```

### Check

Connect

```sh
cockroach sql --insecure
```

Every level should hang off the one above, and no manager should be an orphan:

```sql
WITH RECURSIVE tree AS (
  SELECT id, name, title, manager_id, 0 AS depth
  FROM employees
  WHERE manager_id IS NULL
  UNION ALL
  SELECT e.id, e.name, e.title, e.manager_id, t.depth + 1
  FROM employees e
  JOIN tree t ON e.manager_id = t.id
)
SELECT depth, title, count(*)
FROM tree
GROUP BY depth, title
ORDER BY depth;
```

All 71 rows should be reachable from the root. A count short of 71 means some level failed to chain.

Children should also be spread across every parent, not bunched onto the handful of ids from one batch:

```sql
SELECT count(DISTINCT manager_id) AS parents_used
FROM employees
WHERE title = 'Manager';
```

This should report 15, one for every Director.

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/tree_returning/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/tree_returning/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
