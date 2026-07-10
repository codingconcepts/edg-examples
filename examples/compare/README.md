# Compare

Run the same workload against two databases simultaneously and compare performance. Answers "is Postgres or MySQL faster for my workload?" in one command.

## Postgres vs MySQL

### Setup

```sh
docker compose -f infra/compose_postgres.yml up -d
docker compose -f infra/compose_mysql.yml up -d

until psql "postgres://root:password@localhost:5432/defaultdb" -c "SELECT 1" &>/dev/null; do sleep 1; done
until mysql -u root -ppassword -h 127.0.0.1 -e "SELECT 1" &>/dev/null 2>&1; do sleep 1; done
```

### Run

All-in-one (up, seed, run, deseed, down):

```sh
edg compare all \
--a-driver pgx \
--a-url "postgres://root:password@localhost:5432/defaultdb?sslmode=disable" \
--a-config examples/compare/postgres.edg \
--b-driver mysql \
--b-url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
--b-config examples/compare/mysql.edg \
--rng-seed 42 \
-w 4 \
-d 30s \
--tui
```

Or step-by-step:

```sh
edg compare up \
--a-driver pgx \
--a-url "postgres://root:password@localhost:5432/defaultdb?sslmode=disable" \
--a-config examples/compare/postgres.edg \
--b-driver mysql \
--b-url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
--b-config examples/compare/mysql.edg

edg compare seed \
--a-driver pgx \
--a-url "postgres://root:password@localhost:5432/defaultdb?sslmode=disable" \
--a-config examples/compare/postgres.edg \
--b-driver mysql \
--b-url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
--b-config examples/compare/mysql.edg \
--rng-seed 42

edg compare run \
--a-driver pgx \
--a-url "postgres://root:password@localhost:5432/defaultdb?sslmode=disable" \
--a-config examples/compare/postgres.edg \
--b-driver mysql \
--b-url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
--b-config examples/compare/mysql.edg \
-w 4 \
-d 30s \
--tui
```

### Teardown

```sh
edg compare down \
--a-driver pgx \
--a-url "postgres://root:password@localhost:5432/defaultdb?sslmode=disable" \
--a-config examples/compare/postgres.edg \
--b-driver mysql \
--b-url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
--b-config examples/compare/mysql.edg

docker compose -f infra/compose_postgres.yml down
docker compose -f infra/compose_mysql.yml down
```
