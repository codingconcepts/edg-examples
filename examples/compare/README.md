# Compare

Run one workload against several databases simultaneously and compare performance. Answers "is Postgres, MySQL or CockroachDB faster for my workload?" in one command.

[`compare.edg`](compare.edg) is a **manifest**: it names the databases as targets and points each at its own workload file. `postgres.edg` and `mysql.edg` are ordinary configs with the same query names in each dialect, so the TUI lines their results up. `cockroach` reuses `postgres.edg`, since it speaks the same wire protocol.

```edg
target postgres (url: env('PG_URL'),   driver: 'pgx',   config: 'postgres.edg')
target mysql    (url: env('MY_URL'),   driver: 'mysql', config: 'mysql.edg')
target cockroach(url: env('CRDB_URL'), driver: 'pgx',   config: 'postgres.edg')
```

## Setup

```sh
docker compose -f infra/compose_postgres.yml up -d
docker compose -f infra/compose_mysql.yml up -d
docker compose -f infra/compose_crdb.yml up -d

until psql "postgres://root:password@localhost:5432/defaultdb" -c "SELECT 1" &>/dev/null; do sleep 1; done
until mysql -u root -ppassword -h 127.0.0.1 -e "SELECT 1" &>/dev/null 2>&1; do sleep 1; done
until psql "postgres://root@localhost:26257/defaultdb?sslmode=disable" -c "SELECT 1" &>/dev/null; do sleep 1; done

export PG_URL="postgres://root:password@localhost:5432/defaultdb?sslmode=disable"
export MY_URL="root:password@tcp(localhost:3306)/defaultdb?parseTime=true"
export CRDB_URL="postgres://root@localhost:26257/defaultdb?sslmode=disable"
```

The URLs come from the environment because `url` is an expression - that is what keeps the manifest portable. `config` is the exception: a plain quoted path, checked before anything connects.

## Run

All-in-one (up, seed, run, deseed, down):

```sh
edg all \
--config examples/compare/compare.edg \
--rng-seed 42 \
-w 4 \
-d 30s \
--tui
```

Every command drives every target, so there is one command per phase however many databases you add.

Under `--tui`, `Tab` cycles the merged table, the overlaid graph, and the stats view. All three configs declare the same `stats` queries - a row count and a status mix - so the stats view puts each database's table and charts in its own column, with `←/→` paging them all at once.

Each section is headed by its position and its target name - `A - postgres`, `B - mysql`, `C - cockroach`. The position keys the graph series (`A:lookup_user`) and the delta table, which measures every target against the first.

Add `--pause` to hold the comparison once the run finishes, before the databases are torn down. With `--tui` the final frame stays on screen and `Enter` resumes; without it, a prompt prints after the summary.

Or step-by-step:

```sh
edg up   --config examples/compare/compare.edg
edg seed --config examples/compare/compare.edg --rng-seed 42
edg run  --config examples/compare/compare.edg -w 4 -d 30s --tui
```

### One target at a time

`--target` narrows any command to a single database, workload included - useful for reproducing one target's behaviour on its own:

```sh
edg run --config examples/compare/compare.edg --target mysql -w 4 -d 30s
```

### Dropping a target

Comment a target out to narrow the comparison. The rest still run; `edg` only warns if the manifest is left with a workload nothing uses.

## Teardown

```sh
edg down --config examples/compare/compare.edg

docker compose -f infra/compose_postgres.yml down
docker compose -f infra/compose_mysql.yml down
docker compose -f infra/compose_crdb.yml down
```
