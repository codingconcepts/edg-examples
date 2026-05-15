# Init

Generates a config file based on an existing database.

## CockroachDB

### Setup

```sh
docker compose -f infra/compose_crdb.yml up -d

edg up \
--driver pgx \
--config examples/normal/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```

### Init

```sh
edg init \
--driver pgx \
--url "postgres://root@localhost:26257?sslmode=disable" \
--schema public > _examples/init/crdb.yaml

edg seed \
--driver pgx \
--config examples/init/crdb.yaml \
--url "postgres://root@localhost:26257?sslmode=disable"
```

### Check

```sql
SELECT 'users', count(*) FROM users
UNION ALL SELECT 'vehicles', count(*) FROM vehicles
UNION ALL SELECT 'rides', count(*) FROM rides;
```

### Teardown

```sh
edg deseed \
--driver pgx \
--config examples/init/crdb.yaml \
--url "postgres://root@localhost:26257/movr?sslmode=disable"

edg down \
--driver pgx \
--config examples/init/crdb.yaml \
--url "postgres://root@localhost:26257/movr?sslmode=disable"
```

## MySQL

### Setup

```sh
docker compose -f infra/compose_mysql.yml up -d

edg up \
--driver mysql \
--config examples/normal/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"
```

### Init

```sh
edg init \
--driver mysql \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true" \
--database defaultdb > _examples/init/mysql.yaml
```

### Seed

```sh
edg seed \
--driver mysql \
--config examples/init/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"
```

### Check

```sql
SELECT 'product', count(*) FROM product
UNION ALL SELECT 'review', count(*) FROM review;
```

### Teardown

```sh
edg deseed \
--driver mysql \
--config examples/init/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"

edg down \
--driver mysql \
--config examples/init/mysql.yaml \
--url "root:password@tcp(localhost:3306)/defaultdb?parseTime=true"
```

## MSSQL

### Setup

```sh
docker compose -f infra/compose_mssql.yml up -d

edg up \
--driver mssql \
--config examples/normal/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=master&encrypt=disable"
```

### Init

```sh
edg init \
--driver mssql \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=master&encrypt=disable" \
--schema dbo > _examples/init/mssql.yaml
```

### Seed

```sh
edg seed \
--driver mssql \
--config examples/init/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=master&encrypt=disable"
```

### Check

```sql
SELECT 'product', count(*) FROM product
UNION ALL SELECT 'review', count(*) FROM review;
```

### Teardown

```sh
edg deseed \
--driver mssql \
--config examples/init/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=master&encrypt=disable"

edg down \
--driver mssql \
--config examples/init/mssql.yaml \
--url "sqlserver://sa:P4ssw0rd@localhost:1433?database=master&encrypt=disable"
```

## Oracle

### Setup

```sh
docker compose -f infra/compose_oracle.yml up -d

edg up \
--driver oracle \
--config examples/normal/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"
```

### Init

```sh
edg init \
--driver oracle \
--url "oracle://system:password@localhost:1521/defaultdb" \
--schema SYSTEM > _examples/init/oracle.yaml
```

### Seed

```sh
edg seed \
--driver oracle \
--config examples/init/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"
```

### Check

```sql
SELECT 'product', count(*) FROM product
UNION ALL SELECT 'review', count(*) FROM review;
```

### Teardown

```sh
edg deseed \
--driver oracle \
--config examples/init/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"

edg down \
--driver oracle \
--config examples/init/oracle.yaml \
--url "oracle://system:password@localhost:1521/defaultdb"
```
