# CSV Reference Data

Demonstrates loading CSV files as reference tables at startup using `--csv-file` and `--csv-directory`. CSV files are parsed into reference datasets that work with all `ref_*` functions (`ref_rand`, `ref_same`, `ref_diff`, etc.), just like inline `reference:` data in the YAML config.

Each CSV file becomes a collection named after its filename (minus the extension). For example, `regions.csv` becomes the `regions` reference dataset.

## Flags

| Flag | Description |
|---|---|
| `--csv-file` | Load a single CSV file as a reference table (repeatable) |
| `--csv-directory` | Load all CSV files in a directory as reference tables (repeatable, non-recursive) |

## Run

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

### Single file

```sh
edg up \
  --driver pgx \
  --config examples/csv/config.yaml \
  --csv-file _examples/csv/data/regions.csv \
  --csv-file _examples/csv/data/translations.csv \
  --url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
  --driver pgx \
  --config examples/csv/config.yaml \
  --csv-file _examples/csv/data/regions.csv \
  --csv-file _examples/csv/data/translations.csv \
  --url "postgres://root@localhost:26257?sslmode=disable"
```

### Check

```sh
cockroach sql --insecure \
-e "SELECT email, region, currency, greeting FROM customer"
```

### Teardown

```sh
edg deseed \
  --driver pgx \
  --config examples/csv/config.yaml \
  --url "postgres://root@localhost:26257?sslmode=disable"

edg down \
  --driver pgx \
  --config examples/csv/config.yaml \
  --url "postgres://root@localhost:26257?sslmode=disable"
```

### Directory

```sh
edg up \
  --driver pgx \
  --config examples/csv/config.yaml \
  --csv-directory _examples/csv/data \
  --url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
  --driver pgx \
  --config examples/csv/config.yaml \
  --csv-directory _examples/csv/data \
  --url "postgres://root@localhost:26257?sslmode=disable"
```

### Check

```sh
cockroach sql --insecure \
-e "SELECT email, region, currency, greeting FROM customer"
```

### Teardown

```sh
edg deseed \
  --driver pgx \
  --config examples/csv/config.yaml \
  --url "postgres://root@localhost:26257?sslmode=disable"

edg down \
  --driver pgx \
  --config examples/csv/config.yaml \
  --url "postgres://root@localhost:26257?sslmode=disable"
```

> [!NOTE]
> When using `--csv-directory`, only files with a `.csv` extension are loaded. Subdirectories are not traversed.

### REPL

Explore CSV reference data interactively without a database:

```sh
edg repl \
  --csv-directory _examples/csv/data

>> ref_rand('regions')
map[code:gb currency:GBP name:United Kingdom]

>> ref_rand('translations').greeting
Bonjour

>> ref_same('regions').code
de

>> ref_same('regions').currency
EUR
```

## CSV format

CSV files must include a header row. Column names become map keys in the reference dataset:

```csv
code,name,currency
us,United States,USD
gb,United Kingdom,GBP
de,Germany,EUR
```

This is equivalent to the following YAML `reference:` block:

```yaml
reference:
  regions:
    - {code: us, name: United States, currency: USD}
    - {code: gb, name: United Kingdom, currency: GBP}
    - {code: de, name: Germany, currency: EUR}
```

## Collision detection

If a CSV file has the same stem name as an existing `reference:` dataset in the YAML config, edg will return an error. Rename the CSV file or remove the YAML reference to resolve.
