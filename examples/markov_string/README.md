# Markov String

A places workload whose city, resident and company names are invented by a character-level Markov chain rather than drawn from a fixed list, so the data looks plausible without repeating a few hundred values.

## Functions

| Function | Signature | Returns | Description |
|---|---|---|---|
| `markov_string` | `markov_string(source [, order [, min_len, max_len]])` | `string` | A new string from a chain trained on `source`. Defaults: `order` 2, `min_len` 3, `max_len` 12 |

### Sources

The first argument is a list, or the name of one. A name is split at its **last** dot.

| Form | In this example | Resolves to |
|---|---|---|
| `dataset.field` | `markov_string('fetch_real_cities.name', 3, 4, 14)` | The `name` column of the rows the `fetch_real_cities` init query captured |
| `category.key` | `markov_string('address.city', 3, 4, 14)` | gofakeit's static `address.city` list |
| Inline list | `markov_string(['orbit', 'orion', ...], 2, 4, 9)` | The list as written |

Where a dataset and a gofakeit list share a name, the dataset wins.

### Order

| Order | Behaviour |
|---|---|
| `1` | Each character depends only on the one before it. Mostly unpronounceable |
| `2` | Default. Word-like on short inputs - first names, SKUs |
| `3` | Closer to the source spelling. Better for longer words like cities and company names |
| `4`+ | Approaches the length of the training words, so it reproduces them - and reproductions are rejected, so the vocabulary collapses |

## What it demonstrates

- **Learning from the database** - `fetch_real_cities` reads the 500 city names seeded into `real_city`, and `learned_city` is generated from a chain trained on them. Point it at a production dump and the fake data takes on that data's shape.
- **Learning from gofakeit** - `gofakeit_city`, `resident` and `company` train on gofakeit's static lists without a table in between.
- **Training once** - the chain is built on the first row that reaches it and shared by every worker for the rest of the run, keyed by source and arguments. Keep the arguments constant across rows, or you train a chain per combination.
- **Never returning a training word** - a candidate that appears in the training data is re-rolled, as is one cut off at `max_len` rather than ending where the chain says words end.
- **Uniqueness is not free** - `markov_string` excludes its training data, not its own output. `sku.code` pairs the chain with `seq_global('sku_code')` so the primary key is unique by construction. `uniq_across()` works too, but only while the chain has more distinct words left than rows that need them - and `edg doctor` refuses the config outright where it does not.
- **Variety beats volume in training data** - the SKU chain trains on 19 words across three families (`orbit…`, `vertex…`, `quantum…`) and yields 45 distinct codes. The same chain over eight words that all begin with `o` yields **one**. Run `edg doctor` on this config to see the count for any chain whose source is an inline or gofakeit list.

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
--config examples/markov_string/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/markov_string/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/markov_string/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 4 \
-d 10s
```

### Check

Connect:

```sh
cockroach sql --insecure
```

The names are new, but they read like the lists they came from:

```sql
SELECT learned_city, gofakeit_city, resident, company
FROM place
LIMIT 8;

   learned_city  | gofakeit_city |  resident  |      company
-----------------+---------------+------------+--------------------
  Riverson       | Baton         | Caymon     | Impan Lines
  Los Anto       | Hialeans      | Manion     | Innogrammingeye
  Hendaleans     | Porth         | Coremaace  | Loope
  Garlandler     | Lexington     | Hana       | Environity
  Hiale          | San Beach     | Carriovin  | Ston WebMD
  Hendersburg    | Oaklahoma     | Kaianden   | City Inc
  Corpus Christa | New Orlano    | Bordon     | Civic Data
  St. Paso       | Planta        | Alvi       | Civinite
```

SKU codes, where the chain supplies the shape and the sequence the uniqueness:

```sql
SELECT code, line FROM sku ORDER BY substring(code from '[0-9]+') LIMIT 6;

      code     |    line
---------------+-------------
  vertz-00001  | consumer
  orum-00002   | research
  orbity-00003 | consumer
  veronyx-00004| consumer
  quar-00005   | research
  orionyx-00006| industrial
```

The chain recombines across the three families it was trained on, and produces exactly the 45 words `edg doctor` predicts for it:

```sql
SELECT count(DISTINCT substring(code from '^[a-z]+')) AS distinct_words FROM sku;

  distinct_words
------------------
              45
```

A chain has a finite vocabulary, so distinct values level off well below the row count:

```sql
SELECT count(DISTINCT learned_city) AS distinct_cities, count(*) AS rows
FROM place;

  distinct_cities | rows
------------------+--------
              318 | 27135
```

To widen the vocabulary, train on more rows or **lower** the order. Raising it narrows the chain: it follows the source more closely, so more of what it produces is a training word, and training words are rejected. `markov_string('person.first', 6)` can manage only 21 words for that reason.

Generated names should be absent from the training data:

```sql
SELECT count(*) AS collisions
FROM place p
JOIN real_city c ON c.name = p.learned_city;

  collisions
--------------
           0
```

The same check against `gofakeit_city` need not come out at zero: that chain excludes gofakeit's city list, but `learned_city` only excludes the 500 names it was trained on, so a real city outside that sample can still appear there.

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/markov_string/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/markov_string/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
