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

---

## Moment Subjects (feature removed in v1 transition)

**Removed in:** v1 transition (branch `467-v1-transition-uiux-adjustments`)

**Why kept:** Data retention — subject associations per moment are preserved in case they are needed for future migration or auditing. Subjects are now managed at the strand and lesson level.

**Safe to drop?** Not yet decided. Review data before dropping.

### `moments_subjects`

Join table linking moments to subjects. Replaced by lesson-level subject management.

| Column | Type | Description |
|---|---|---|
| `moment_id` | bigint | FK → `moments.id` |
| `subject_id` | bigint | FK → `subjects.id` |

---

## Moment Cards (feature removed in v1 transition)

**Removed in:** v1 transition (branch `467-v1-transition-uiux-adjustments`)

**Why kept:** Data retention — moment card data is preserved in case it is needed for future migration or auditing.

**Safe to drop?** Not yet decided. Review data before dropping.

### `moment_cards`

Cards associated with a moment, used for extra organization within moments.

| Column | Type | Description |
|---|---|---|
| `id` | bigint | Primary key |
| `name` | text | Card name |
| `description` | text | Card content (markdown) |
| `position` | integer | Display order |
| `shared_with_students` | boolean | Whether visible to students |
| `moment_id` | bigint | FK → `moments.id` |
| `school_id` | bigint | FK → `schools.id` |
| `inserted_at` | timestamp | |
| `updated_at` | timestamp | |

### `moment_cards_attachments`

Join table linking moment cards to file attachments.

| Column | Type | Description |
|---|---|---|
| `id` | bigint | Primary key |
| `position` | integer | Display order |
| `shared_with_students` | boolean | Whether attachment is visible to students |
| `owner_id` | bigint | FK → `profiles.id` |
| `moment_card_id` | bigint | FK → `moment_cards.id` |
| `attachment_id` | bigint | FK → `attachments.id` |
| `inserted_at` | timestamp | |
| `updated_at` | timestamp | |

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

---

## Profile Report Card Filters (feature removed — class filter migrated to URL state)

**Removed in:** branch `546-students-order-in-report-card`

**Why kept:** Data retention — persisted per-profile report card class filters are kept
in case they are needed for auditing. The report card class filter is now driven entirely
by the `classes_ids` URL param and no longer persists across sessions.

**Safe to drop?** Not yet decided. Review data before dropping.

### `profile_report_card_filters`

Stored a profile's selected class / linked-students-class filters within a report card.

| Column | Type | Description |
|---|---|---|
| `id` | bigint | Primary key |
| `profile_id` | bigint | FK → `profiles.id` |
| `report_card_id` | bigint | FK → `report_cards.id` |
| `class_id` | bigint | FK → `classes.id` (report card classes filter) |
| `linked_students_class_id` | bigint | FK → `classes.id` (linked students classes filter) |
| `inserted_at` | timestamp | |
| `updated_at` | timestamp | |
