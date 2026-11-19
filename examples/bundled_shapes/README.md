# Bundled Shapes

`qps: signal('name', peak: N)` drives a stage's rate limiter from a pre-computed curve. [`qps_shapes/`](../qps_shapes) writes those curves by hand. This example writes none: edg ships with ten shapes, named with an `edg-` prefix, that need no expression and no declaration.

```edg
stages {
  find_the_knee(workers: 16, duration: 2m, qps: signal('edg-staircase', peak: 1000))
}
```

Three of them run here, back to back, each answering a different question.

## The shapes

| Stage | Shape | Question |
|---|---|---|
| `find_the_knee` | `edg-staircase` | Five flat steps to 1,000 QPS. Where does latency bend - and what is the p99 at each level either side of it? |
| `flash_crowd` | `edg-spike` | Flat at 200 QPS, then one short burst to 1,000. Absorbed, or queued behind? |
| `recovery` | `edg-outage` | Steady at 500 QPS, then near-nothing, then a surge to 1,000 that settles back. What does the catch-up cost? |

`peak` maps the tallest point of a shape to the QPS you give it and scales the rest, so the shapes are written to run between 0 and 1. That means `peak` is not always the load you see most of the time: `edg-spike` spends its life at a fifth of `peak`, and `edg-outage` either side of the surge at half.

Position is measured from the start of the run, not the start of the stage, so each stage here sees its own shape in full only because each one is the shape's whole timeline. A shape has no interval of its own, so it stretches across whatever the run turns out to be.

## The rest of them

```sh
edg signals
```

```
edg-ramp             Climbs steadily from nothing to full load.
edg-staircase        Climbs in five flat steps, holding each one long enough to measure.
edg-ramp-hold        Climbs for a tenth of the run, holds flat, then winds back down.
edg-business-hours   Quiet at both ends, one broad rise and fall in the middle, never fully idle.
edg-two-peaks        A smaller morning rush and a larger evening one, quiet in between.
edg-week             Seven days of business hours, with the weekend running at a third of weekday load.
edg-spike            Flat and low, then one short burst of five times the load, then flat again.
edg-batch            Twelve square bursts of work with near-idle gaps between them.
edg-backlog          Builds up twelve times over, each time dropping back to nothing all at once.
edg-outage           Steady, then almost nothing for a tenth of the run, then a catch-up surge that settles back.
```

## Changing one

The shapes take no options. To change one, print it as a declaration and edit that:

```sh
edg signals --show edg-staircase
```

```edg
# Climbs in five flat steps, holding each one long enough to measure.
signal staircase(length: 288) {
  (floor(i * 5 / 288.0) + 1) / 5
}
```

The `5`s are the step count. `--length` prints the same shape at a different resolution, and swapping `length` for `from`/`to`/`interval` anchors it to a simulated clock the way [`qps_shapes/`](../qps_shapes) does.

## Running it

```sh
edg all --config crdb.edg --url "postgres://root@localhost:26257?sslmode=disable"
```

`all` drops the table as soon as the run finishes. To query what the three shapes wrote before that happens, add `--pause` and press enter when you are done:

```sh
edg all --config crdb.edg --url "postgres://root@localhost:26257?sslmode=disable" --pause
```
