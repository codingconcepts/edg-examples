# Tree

Declarative tree and DAG generation using the `tree:` config section. Instead of writing one seed query per level manually, specify the shape with `levels` and let edg expand it.

This example generates two structures:

**Tree** - org chart (self-referential FK, strict parent-child):
- 1 root (CEO)
- 5 level-1 (VPs)
- 15 level-2 (Directors)
- 50 level-3 (Managers)
- 200 level-4 (ICs)

**DAG** - dependency graph (`dag: true`, nodes can reference any prior level):
- 3 roots
- 8 mid-tier
- 20 leaves

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
```

### Run

```sh
go run ./cmd/edg up \
--driver pgx \
--config _examples/tree/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

go run ./cmd/edg seed \
--driver pgx \
--config _examples/tree/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```

### Check

Connect

```sh
cockroach sql --insecure
```

Tree query

```sql
WITH RECURSIVE tree AS (
  SELECT id, name, manager_id, 0 AS depth,
         name::STRING AS path
  FROM employees
  WHERE manager_id IS NULL

  UNION ALL

  SELECT e.id, e.name, e.manager_id, t.depth + 1,
         t.path || '/' || e.name
  FROM employees e
  JOIN tree t ON e.manager_id = t.id
)
SELECT
  repeat('  ', depth) || name AS org_chart
FROM tree
ORDER BY path
LIMIT 30;
```

DAG query

```sql
WITH RECURSIVE graph AS (
  SELECT id, name, dependency_id, 0 AS depth,
         name::STRING AS path
  FROM dependencies
  WHERE dependency_id IS NULL

  UNION ALL

  SELECT d.id, d.name, d.dependency_id, g.depth + 1,
         g.path || ' -> ' || d.name
  FROM dependencies d
  JOIN graph g ON d.dependency_id = g.id
)
SELECT
  repeat('  ', depth) || name AS dep_graph,
  path
FROM graph
ORDER BY path;
```

### Teardown

```sh
go run ./cmd/edg deseed \
--driver pgx \
--config _examples/tree/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"

go run ./cmd/edg down \
--driver pgx \
--config _examples/tree/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```
