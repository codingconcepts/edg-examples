# Cluster

Distributed workload runner with CockroachDB coordination. Multiple agents across regions execute workloads with synchronized stages and global QPS control.

## Setup

Start CockroachDB:

```sh
docker compose -f infra/compose_crdb.yml up -d
docker exec -it node1 cockroach init --insecure
```

Create the coordination database:

```sh
cockroach sql --insecure -e "CREATE DATABASE edg_cluster"
```

## Run

Start the coordinator:

```sh
edg cluster coordinator \
--crdb-url "postgres://root@localhost:26257/edg_cluster?sslmode=disable"
```

Start two agents (in separate terminals):

```sh
edg cluster agent \
--crdb-url "postgres://root@localhost:26257/edg_cluster?sslmode=disable" \
--region us-east
```

```sh
edg cluster agent \
--crdb-url "postgres://root@localhost:26257/edg_cluster?sslmode=disable" \
--region eu-west
```

Submit a workload:

```sh
edg cluster submit \
--target-url "postgres://root@localhost:26257/defaultdb?sslmode=disable" \
--config examples/cluster/crdb.edg \
--duration 2m \
--workers 5 \
--stream
```

Check status:

```sh
edg cluster status
```

List active agents:

```sh
edg cluster agents
```

Teardown

```sh
edg cluster reset --crdb-url "postgres://root@localhost:26257/defaultdb?sslmode=disable"
```