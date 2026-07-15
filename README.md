<p align="center">
  <img src="assets/logo.png" alt="drawing" width="350"/>
</p>

# edg examples

Complete workload configs for [edg](https://github.com/codingconcepts/edg). Run them directly or use as starting points for your own.

## Quick start

```sh
git clone https://github.com/codingconcepts/edg-examples.git
cd edg-examples

edg all \
  --driver pgx \
  --config examples/minimal/crdb.edg \
  --url "postgres://root@localhost:26257?sslmode=disable" \
  -w 1 -d 10s
```

## Getting Started

| Example | Description |
|---|---|
| [Minimal](examples/minimal/) | Starter workload for building familiarity with edg |
| [Remote Config](examples/remote_config/) | Load a workload config from an HTTP/HTTPS URL |
| [Workload](examples/workload/) | Built-in workloads without a config file |

## AI Workloads

| Example | Description |
|---|---|
| [Complete](examples/complete/) | LLM text generation |
| [Complete Array](examples/complete_array/) | LLM batch generation |
| [Embed](examples/embed/) | Real embeddings via OpenAI-compatible APIs |
| [Vector](examples/vector/) | pgvector embeddings with clustered vectors |

## Data Generation

| Example | Description |
|---|---|
| [Batch](examples/batch/) | `query_batch` and `exec_batch` for batch inserts and updates |
| [Blob](examples/blob/) | Binary data with `blob()` and `bytes()` |
| [CSV](examples/csv/) | CSV files as reference data sources |
| [Distributions](examples/distributions/) | Uniform, zipf, norm_f, exp_f, and lognorm_f |
| [Expressions](examples/expression/) | expr-lang built-in features (array, map, string, bitwise) |
| [Global Sequences](examples/global_sequences/) | Auto-incrementing sequences shared across all workers |
| [Locale](examples/locale/) | Locale-aware PII generation with deterministic masking |
| [Normal](examples/normal/) | Product reviews with normal distribution ratings |
| [Nullable](examples/nullable/) | `nullable(expr, probability)` for injecting NULLs |
| [Reference Data](examples/reference_data/) | Static reference datasets without database queries |
| [Sequences](examples/sequences/) | Per-worker auto-incrementing sequences |
| [Timestamp Step](examples/timestamp_step/) | Interval-aligned timestamp generation |

## Schema Patterns

| Example | Description |
|---|---|
| [Composite Types](examples/composite_types/) | PostgreSQL composite types with `ROW(...)::type` |
| [Each Cartesian](examples/each_cartesian/) | Cartesian product seeding with `ref_each` |
| [Exclusive Columns](examples/exclusive_columns/) | Mutually exclusive columns (either col_a or col_b) |
| [Includes](examples/includes/) | Splitting and reusing config fragments with `!include` |
| [Invoice Lines](examples/invoice_lines/) | Correlated totals with `distribute_sum()` and `distribute_weighted()` |
| [LTREE](examples/ltree/) | Hierarchical data using PostgreSQL's `ltree` extension |
| [Multi-Row DML](examples/multi_row_dml/) | `__values__` token for cross-driver multi-row INSERT/UPSERT/UPDATE |
| [Named Args](examples/named_args/) | Map-style args with `arg('name')` |
| [Objects](examples/objects/) | Reusable arg templates shared across queries |
| [Org Tree](examples/org_tree/) | Hierarchical org chart using seed capture |
| [Tree](examples/tree/) | Recursive tree structure generation |

## Application Workloads

| Example | Description |
|---|---|
| [Bank](examples/bank/) | Bank account operations for contention and correctness testing |
| [E-Commerce](examples/ecommerce/) | Categories, products, customers, and orders |
| [IoT](examples/iot/) | Devices, sensors, and time-series readings |
| [SaaS](examples/saas/) | Multi-tenant with tenants, users, projects, and tasks |
| [Social](examples/social/) | Users, posts, follows, and tags |

## Benchmarks

| Example | Description |
|---|---|
| [Anomalies](examples/anomalies/) | Read/write anomaly patterns for isolation level testing |
| [Index Comparison](examples/index_comparison/) | Indexed vs unindexed lookup comparison with expectations |
| [Populate](examples/populate/) | Billion-row data population benchmark |
| [TPC-C](examples/tpcc/) | Full TPC-C benchmark with all 5 transaction profiles |
| [YCSB](examples/ycsb/) | Yahoo! Cloud Serving Benchmark |

## Execution Control

| Example | Description |
|---|---|
| [Conditional If](examples/conditional_if/) | Conditional query execution with `if` |
| [Conditional Match](examples/conditional_match/) | Pattern-based conditional query execution |
| [Environment](examples/environment/) | Fetching and using environment variables |
| [Expectations](examples/expectations/) | Post-run assertions for CI/CD gating |
| [Failing](examples/failing/) | Map lookup with `fail()` to validate and stop workers |
| [Pipeline](examples/pipeline/) | Multi-table sequential reads and writes |
| [Prepared](examples/prepared/) | Prepared statements for reduced parse overhead |
| [Print](examples/print/) | Live aggregated stats with `print` expressions |
| [Stages](examples/stages/) | Staged execution with varying worker counts and durations |
| [Stages Run Weights](examples/stages_run_weights/) | Per-stage `run_weights` overrides |
| [Temporal Patterns](examples/temporal_patterns/) | Data drift over time with `global_iter()` |
| [Transaction](examples/transaction/) | Multi-statement transactions (SQL, MongoDB, Cassandra) |
| [Workers](examples/workers/) | Background worker queries alongside the main run loop |

## Infrastructure

| Example | Description |
|---|---|
| [Cassandra](examples/cassandra/) | Cassandra with keyspaces, tables, and batch inserts |
| [MongoDB](examples/mongodb/) | MongoDB with BSON/JSON command syntax |
| [Observability](examples/observability/) | Prometheus metrics and Grafana dashboard |
| [Output](examples/output/) | `stage` output formats (SQL, JSON, CSV, Parquet, stdout) |
| [Serve](examples/serve/) | Job server with HTTP API |
| [Sync](examples/sync/) | Dual-write consistency testing across databases |

## Complete Examples

| Example | Description |
|---|---|
| [Aggregation](examples/aggregation/) | Aggregation functions (sum, avg, min, max, count, distinct) |
| [Geo Spatial](examples/geo_spatial/) | Location-based discovery with `ST_DWithin` and GiST index |
| [Init](examples/init/) | Generate starter config from an existing schema |
