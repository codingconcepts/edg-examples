# Realistic PII with Locale

Generates locale-aware personal data with optional masking for non-production environments.

## What it demonstrates

- `gen_locale()` for locale-specific names, addresses, and phone numbers
- `mask()` for deterministic pseudonymization of PII fields
- Mixing locales in a single workload (JP region + DE region)

## Run

```bash
# Generate to CSV.
edg stage \
--config examples/locale/crdb.edg \
--format csv \
--output-dir _examples/locale/csv/

# With deterministic output.
edg stage \
--config examples/locale/crdb.edg \
--format csv \
--output-dir _examples/locale/csv/ \
--rng-seed 42
```
