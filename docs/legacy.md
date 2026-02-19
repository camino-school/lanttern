# Legacy Database Tables

This document lists database tables that are retained for historical/data purposes
but are no longer backed by application code. Do not use these tables for new features.

---

## Notes (feature removed in v1 transition)

**Removed in:** v1 transition — commits `396f8095`, `ce14f337` (branch `467-v1-transition-uiux-adjustments`)

**Why kept:** Data retention — historical note data is preserved in case it is needed for future migration or auditing.

**Safe to drop?** Not yet decided. Review data before dropping.

### `notes` (public schema)

Main notes table. Each row is a text note authored by a profile.

| Column | Type | Description |
|---|---|---|
| `id` | bigint | Primary key |
| `description` | text | Note content |
| `author_id` | bigint | FK → `profiles.id` |
| `inserted_at` | timestamp | |
| `updated_at` | timestamp | |

### `strands_notes`

Join table enforcing one note per profile per strand (composite FK).

| Column | Type | Description |
|---|---|---|
| `strand_id` | bigint | FK → `strands.id` |
| `note_id` | bigint | FK → `notes.id` |
| `author_id` | bigint | FK → `profiles.id` |

### `moments_notes`

Join table enforcing one note per profile per moment (originally named `activities_notes`,
renamed in migration `20240130120758`).

| Column | Type | Description |
|---|---|---|
| `moment_id` | bigint | FK → `moments.id` |
| `note_id` | bigint | FK → `notes.id` |
| `author_id` | bigint | FK → `profiles.id` |

### `notes_attachments`

Join table connecting notes to file attachments.

| Column | Type | Description |
|---|---|---|
| `id` | bigint | Primary key |
| `position` | integer | Display order |
| `owner_id` | bigint | FK → `profiles.id` |
| `note_id` | bigint | FK → `notes.id` |
| `attachment_id` | bigint | FK → `attachments.id` |
| `inserted_at` | timestamp | |
| `updated_at` | timestamp | |

### `log.notes` (log schema)

Audit log for note operations (CREATE, UPDATE, DELETE).

| Column | Type | Description |
|---|---|---|
| `id` | bigint | Primary key |
| `note_id` | bigint | References the original `notes.id` |
| `author_id` | bigint | References the original `profiles.id` |
| `description` | text | Note content at time of operation |
| `operation` | text | `CREATE`, `UPDATE`, or `DELETE` |
| `type` | text | Optional context type |
| `type_id` | bigint | Optional context ID |
| `inserted_at` | timestamp | |
