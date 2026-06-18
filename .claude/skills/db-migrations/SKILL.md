---
description: Create or edit a database migration in Lanttern. Use whenever generating, writing, or editing an Ecto migration — especially when adding text/string columns that will be sorted alphabetically. Usage: /db-migrations [description]
---

## Your task

Create or edit an Ecto migration following Lanttern's conventions below.

### Generating the migration

Always generate the file via the CLI first, then edit it:

```
mix ecto.gen.migration <name>
```

Never create a migration file manually.

### Legacy tables

Consult `docs/legacy.md` before touching older tables.

### Sortable text collation (`und-x-icu`)

Any new `text`/`string` column that will be ordered alphabetically — names, titles,
labels, anything used in an `ORDER BY` or `preload_order` — **must** be created with
the `und-x-icu` collation. The cluster default collation is unreliable: it differs
between local dev and Supabase prod, so accented characters sort inconsistently
(e.g. *Érico* lands after *Eric*, not last).

`add/3` has no collation option, so set it with raw SQL right after the table/column
is created:

```elixir
execute(
  ~s|ALTER TABLE my_table ALTER COLUMN name SET DATA TYPE text COLLATE "und-x-icu"|,
  ~s|ALTER TABLE my_table ALTER COLUMN name SET DATA TYPE text COLLATE pg_catalog."default"|
)
```

Rules:

- Use the **deterministic** ICU collation (the default — do *not* pass
  `deterministic: false`) so unique indexes, `LIKE`, and `pg_trgm` search keep working.
- This makes `ORDER BY name` accent-aware automatically — never add per-query
  `COLLATE` fragments.
- See migration `set_icu_collation_on_name_columns`
  (`priv/repo/migrations/20260602000443_set_icu_collation_on_name_columns.exs`)
  for the established pattern.
