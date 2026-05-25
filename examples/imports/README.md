# Imports

This example demonstrates the `import` and `pub` keywords for sharing definitions across `.edg` files.

## Structure

```
imports/
  objects/
    customer.edg # Customer-related objects (pub object)
  shared.edg     # Shared globals (pub let)
  crdb.edg       # CockroachDB workload importing shared.edg
```

## What can be imported

The `pub` keyword works with:

- `pub let` - global variables
- `pub object` - data generation objects
- `pub ref` - reference datasets
- `pub expr` - expression definitions
- `pub seq` - sequence definitions
- `pub template` - query templates

Only `pub`-marked declarations are visible to the importing file. Everything else stays private.

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
--config examples/imports/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```

## Teardown

```sh
docker ps -aq | xargs docker rm -f
```