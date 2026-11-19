# Targets

Drive the same workload against several databases at once from a single
process, and see each one's numbers side by side.

A `target` block names one database the run drives. A config with no
targets drives the single database given by `--url`/`--driver`, exactly
as it always has. A config with several drives them all concurrently,
one connection and one workload stream each.

Both target options are expressions rather than bare text, so the config
names the *roles* and the environment supplies the *addresses*:

```edg
target crdb(url: env('CRDB_URL'))
target postgres(url: env('POSTGRES_URL'))
```

`driver` is optional and falls back to `--driver`. Here both targets
speak pgx, so neither declares one.

## One workload or several?

The targets here share this config's workload, which is the right shape
when the same SQL runs everywhere: a cluster vs its replica, two sizings
of the same engine, a canary vs production.

When targets need *different* SQL - Postgres against Oracle, say - give
each one its own workload file with `config`:

```edg
target postgres(url: env('PG_URL'),  driver: 'pgx',    config: 'postgres.edg')
target oracle(  url: env('ORA_URL'), driver: 'oracle', config: 'oracle.edg')
```

Both styles mix in one manifest, and both run the same way. See
[`examples/compare/`](../compare).

## CockroachDB and Postgres

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure

docker compose -f infra/compose_postgres.yml up -d
until psql "postgres://root:password@localhost:5432/defaultdb" -c "SELECT 1" &>/dev/null; do sleep 1; done
```

```sh
export CRDB_URL="postgres://root@localhost:26257/defaultdb?sslmode=disable"
export POSTGRES_URL="postgres://root:password@localhost:5432/defaultdb?sslmode=disable"
```

### Prepare each target

`up`, `seed`, `deseed` and `down` act on a single database: the first
declared target, or whichever one `--target` names. Only `run` drives
every target. So prepare them one at a time:

```sh
edg up   --driver pgx --config examples/targets/postgres.edg --target crdb
edg seed --driver pgx --config examples/targets/postgres.edg --target crdb

edg up   --driver pgx --config examples/targets/postgres.edg --target postgres
edg seed --driver pgx --config examples/targets/postgres.edg --target postgres
```

`--url` is ignored once a config declares targets - the target's own
`url` is what it connects to.

### Run

```sh
edg run \
--driver pgx \
--config examples/targets/postgres.edg \
-w 4 \
-d 30s \
--tui
```

Every target gets its own progress section and its own summary, plus a
delta table comparing each target against the first.

`--max-queries` and `--max-qps` apply *per target* rather than across the
run: targets are separate workload streams, and a shared budget would let
a fast target starve a slow one, which would make the comparison
meaningless.

`--target` works here too, narrowing the run down to one database when
you want to reproduce a single target's behaviour on its own:

```sh
edg run --driver pgx --config examples/targets/postgres.edg --target postgres -w 4 -d 30s
```

### Teardown

```sh
edg deseed --driver pgx --config examples/targets/postgres.edg --target crdb
edg down   --driver pgx --config examples/targets/postgres.edg --target crdb

edg deseed --driver pgx --config examples/targets/postgres.edg --target postgres
edg down   --driver pgx --config examples/targets/postgres.edg --target postgres
```
