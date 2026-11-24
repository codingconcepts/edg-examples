# Polymorphic

Demonstrates polymorphic associations: a child table whose foreign key can point at more than one parent table, with a type column saying which. Covers both shapes, Single Table Inheritance (STI) and Multiple Table Inheritance (MTI).

A `comment` can belong to a `post` or a `video`. So can a `reaction`. Each one models the relationship differently.

## How it works

The type column is generated first, then every other column branches on it with `cond()` and `arg()`. Because the branch reads the already-generated type, the type and the foreign key can never disagree.

### STI: one id column, one type column

```edg
populate_comment(type: exec_batch, count: comments, size: batch_size) `INSERT INTO comment (commentable_type, commentable_id, body)
  __values__` (
  commentable_type: uniform.set(['post', 'video'], [70, 30]),
  commentable_id: cond(arg('commentable_type') == 'post', ref('populate_post').id, ref('populate_video').id),
  body: gen('loremipsumsentence:12')
)
```

`commentable_id` points into `post` or `video` depending on `commentable_type`. The database can't enforce this with a foreign key, which is the usual trade-off with STI.

### MTI: one nullable foreign key per parent

```edg
populate_reaction(type: exec_batch, count: reactions, size: batch_size) `INSERT INTO reaction (target_type, post_id, video_id, kind)
  __values__` (
  target_type: uniform.set(['post', 'video'], [70, 30]),
  post_id: cond(arg('target_type') == 'post', ref('populate_post').id, nil),
  video_id: cond(arg('target_type') == 'video', ref('populate_video').id, nil),
  kind: uniform.set(['like', 'love', 'celebrate'], [60, 30, 10])
)
```

Exactly one of `post_id` and `video_id` is set, the other is `nil`, which reaches the database as `NULL`. Both are real foreign keys, and a CHECK constraint enforces the exclusive arc. See [Exclusive Columns](../exclusive_columns/) for the same NULL technique without the type column.

### Controlling the mix

The weights on `uniform.set` set the ratio of parent types, here 70% posts to 30% videos. That ratio is independent of how many posts and videos exist, so you can seed 500 posts and 200 videos and still skew comments however you like.

### Referencing the parents

`ref('populate_post')` reads the rows an earlier seed query generated, so no `SELECT` round-trip is needed. The `id` values come from the `post_id` and `video_id` sequences used when seeding the parents.

## Schema

`comment` carries a type discriminator and an unconstrained id:

```sql
commentable_type STRING NOT NULL,
commentable_id INT NOT NULL
```

`reaction` carries a type discriminator and one nullable foreign key per parent, with the arc enforced:

```sql
CHECK (
  (target_type = 'post' AND post_id IS NOT NULL AND video_id IS NULL) OR
  (target_type = 'video' AND post_id IS NULL AND video_id IS NOT NULL)
)
```

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
--config examples/polymorphic/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```

## MySQL

### Setup

```sh
docker compose -f infra/compose_mysql.yml up -d
```

### Run

```sh
edg all \
--driver mysql \
--config examples/polymorphic/mysql.edg \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"
```

## Oracle

### Setup

```sh
docker compose -f infra/compose_oracle.yml up -d
```

### Run

```sh
edg all \
--driver oracle \
--config examples/polymorphic/oracle.edg \
--url "oracle://system:password@localhost:1521/defaultdb"
```

Oracle reserves `comment`, so the table is named `comment_log` there.

## MSSQL

### Setup

```sh
docker compose -f infra/compose_mssql.yml up -d
```

### Run

```sh
edg all \
--driver mssql \
--config examples/polymorphic/mssql.edg \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=polymorphic&encrypt=disable"
```
