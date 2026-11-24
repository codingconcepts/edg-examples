# Nested Targets

Drive several *groups* of workloads, against several databases, from one
command. A target's `config` may name a config that declares targets of
its own; that config is a **manifest**, and the target naming it stands
for everything the manifest declares.

Four files, four workload streams:

```
all.edg                 # the databases
└── group.edg           # the workloads each of them runs
    ├── oltp.edg        # point reads and writes
    └── olap.edg        # scans and aggregates
```

```edg
# all.edg
target cockroach(url: env('CRDB_URL'), driver: 'pgx', config: 'group.edg')
target postgres(url: env('POSTGRES_URL'), driver: 'pgx', config: 'group.edg')
```
```edg
# group.edg
target oltp(config: 'oltp.edg')
target olap(config: 'olap.edg')
```

Running `all.edg` gives four targets:

```
A - cockroach.oltp
B - cockroach.olap
C - postgres.oltp
D - postgres.olap
```

A nested target is named for the path that reached it, joined with `.`.
That name is what `--target` matches, what heads each section of the
display, and what labels its metrics. It is also why both groups can
have an `oltp` in them without colliding.

## What gets inherited

`group.edg` names no `url` and no `driver`. Both are inherited from the
target that pointed at it, which is what lets one group be aimed at two
databases without being written out twice. A nested target that names
its own `url` or `driver` keeps it; only what it leaves out is filled in
from above.

`oltp.edg` and `olap.edg` are ordinary configs. They declare no targets,
know nothing of each other, and still run standalone against `--url`:

```sh
edg all --driver pgx --config examples/nested_targets/oltp.edg --url "$CRDB_URL" -w 4 -d 30s
```

`group.edg` is the exception: its targets have no `url` of their own, so
it only runs with a parent supplying one. Give its targets urls too and
it runs on its own as well.

## Setup

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

## Run

```sh
edg all \
--config examples/nested_targets/all.edg \
-w 4 \
-d 30s \
--tui
```

`up`, `seed`, `run`, `deseed` and `down` each act on all four targets, so
the number of commands doesn't grow with the size of the tree.

Narrow to one database's OLAP workload with its qualified name:

```sh
edg run --config examples/nested_targets/all.edg --target postgres.olap -w 4 -d 30s
```

Or run one group on its own by starting a level down - every file in the
tree is a config in its own right:

```sh
edg run --config examples/nested_targets/oltp.edg --driver pgx --url "$CRDB_URL" -w 4 -d 30s
```

## Teardown

```sh
edg down --config examples/nested_targets/all.edg

docker compose -f infra/compose_crdb.yml down
docker compose -f infra/compose_postgres.yml down
```
