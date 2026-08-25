# Geo Spatial

A dating app workload with user profiles, location-based discovery, swipes, matches, and messaging.

## Functions

| Function | Signature | Returns | Description |
|---|---|---|---|
| `polygon_wkt` | `polygon_wkt(lat, lon, min_km, max_km, points)` | `string` | WKT polygon around a point, used to seed zone boundaries |
| `geo_distance` | `geo_distance(lat1, lon1, lat2, lon2)` | `float64` | Great-circle distance in kilometres |
| `geo_bearing` | `geo_bearing(lat1, lon1, lat2, lon2)` | `float64` | Initial compass bearing in degrees, `[0, 360)` where 0 is north |

`geo_distance` and `geo_bearing` compute the geometry in the generator rather than the database, so the `log_encounter` query can write a pre-computed `distance_km` and `bearing_deg` without a round trip. The `viewer` profile is pinned for the lifetime of the worker with `ref_perm`, and the `viewed` profile is drawn per execution with `ref_same` so that its `lat` and `lon` come from the same row.

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

# Generator-computed distance and bearing against the database's own calculation.
cockroach sql --insecure \
-e "SELECT e.distance_km, e.bearing_deg,
      ST_Distance(a.location, b.location) / 1000.0 AS db_distance_km
    FROM encounter e
    JOIN profile a ON a.id = e.viewer_id
    JOIN profile b ON b.id = e.viewed_id
    LIMIT 5"
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
