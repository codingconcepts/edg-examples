# Named Args

Demonstrates the named args syntax, where `args` is a map instead of a list. Named args let you reference values by name with `arg('name')` instead of by index with `arg(0)`.

## Positional vs named

Positional (existing):

```edg
args:
  - gen('email')
  - ref_same('regions').name
  - set_rand(ref_same('regions').cities, [])
  - uniform(1, 500)
print:
  - arg(3)
```

Named (equivalent):

```edg
args:
  email: gen('email')
  region: ref_same('regions').name
  city: set_rand(ref_same('regions').cities, [])
  amount: uniform(1, 500)
print:
  - arg('amount')
```

Named args bind to `$1`, `$2`, etc. in declaration order, so query placeholders work identically. The only difference is how you reference previously computed args within expressions.

> [!NOTE]
> Index-based `arg(0)` still works with named args. Named and positional references can be mixed within expressions.

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
--config examples/named_args/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/named_args/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/named_args/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 10s

edg deseed \
--driver pgx \
--config examples/named_args/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/named_args/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
