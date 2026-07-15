# Geo Spatial

A dating app workload with user profiles, location-based discovery, swipes, matches, and messaging.

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
--config examples/geo_spatial/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg seed \
--driver pgx \
--config examples/geo_spatial/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg run \
--driver pgx \
--config examples/geo_spatial/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable" \
-w 10 \
-d 30s
```

Check data

```sh
# Left and right swipes.
cockroach sql --insecure \
-e "SELECT direction, COUNT(*) FROM swipe GROUP BY direction"

# Zone with boundary as WKT.
cockroach sql --insecure \
-e "SELECT id, name, ST_AsText(boundary::GEOMETRY) AS boundary FROM zone LIMIT 1"
```

```sh
edg deseed \
--driver pgx \
--config examples/geo_spatial/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"

edg down \
--driver pgx \
--config examples/geo_spatial/crdb.edg \
--url "postgres://root@localhost:26257?sslmode=disable"
```
