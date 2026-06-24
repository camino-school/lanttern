# Strand Lock (`is_locked`) — Implementation Plan

Tracks issue **#564 — prevent strand changes**. Living document: update the
status checkboxes as commits land.

## Goal

Add an `is_locked` flag to strands. When a strand is locked, **all** mutations to
the strand and its related data (moments/lessons, assessment points, grade
entries/markings, etc.) are blocked — **except** for users holding a new
`strand_management` permission, who can both edit locked strands and toggle the
lock.

## Decisions (locked in)

- **Field name:** `is_locked` (matches the `is_`/`has_` boolean convention, e.g. `is_starred`).
- **Permission name:** `strand_management` (matches the existing `*_management` convention).
- **Lock scope:** blocks **everything** strand-owned, **including grade entries (markings)**.
- **Strand reports:** **excluded** — governed by the report-card lifecycle, not the strand lock.
- **Lesson tags:** **excluded** — school-owned, not strand-owned.
- **Failure mode:** **raise** on locked-without-permission (consistent with the codebase's
  `true = Scope.has_permission?(...)` style). UI hides affordances so it's defense-in-depth.
- **No audit-log mirror:** strands have no `log`-prefixed table, so no paired log alter is needed.

## Architecture

1. **`strands.is_locked`** — real `:boolean`, `null: false, default: false`.
   **Not castable** in `Strand.changeset/2` so content edits can never flip the lock.
2. **Lock toggle** — dedicated `lock_strand/2` & `unlock_strand/2` in the **`Strands`**
   context (`lib/lanttern/strands.ex`), each gated by
   `true = Scope.has_permission?(scope, "strand_management")`, using a lock-only changeset.
3. **Central guard** — `Strands.ensure_strand_editable!(scope, strand_id)`:
   ```elixir
   if strand_locked?(strand_id) and not Scope.has_permission?(scope, "strand_management"),
     do: raise(...)
   ```
   Called at the top of every strand-owned mutation after resolving the owning `strand_id`.
4. **Strand resolution** — nested entities resolve up to their strand:
   entry → `assessment_point_id` → (`strand_id | moment_id | lesson_id`) → strand.
   Bulk `save_assessment_point_entries` resolves distinct APs once, not per-row.

## Steps

### Step 1 — Migration + schema field ✅
- [x] Migration: `add_is_locked_to_strands` — `is_locked :boolean, null: false, default: false` (applied).
- [x] `Strand` schema: `field :is_locked, :boolean, default: false`, added to `@type t`.
- [x] Kept `is_locked` **out** of `Strand.changeset/2` cast list.
- [x] Added lock-only changeset `Strand.lock_changeset/2`.
- [x] Validated: `mix compile --warning-as-errors`, `mix format`.

### Step 2 — Permission + context plumbing
- [ ] Add `"strand_management"` to `@valid_permissions` (`personalization.ex`).
- [ ] Add label to `@permission_to_option_map` (`personalization_helpers.ex`).
- [ ] `Strands.lock_strand/2` & `unlock_strand/2` (permission-gated).
- [ ] `Strands.strand_locked?/1` + `ensure_strand_editable!/2` central guard.

> **Note:** `LearningContext` is being phased out. **All new** strand-related functions
> (lock toggle, guard, `strand_locked?`) go in the **`Strands`** context. Existing
> mutation functions in `LearningContext`/Assessments/Lessons stay where they are for
> the Step 3 sweep, but call into `Strands.ensure_strand_editable!/2` for the guard.

### Step 3 — Enforcement sweep (guard + thread Scope where missing)

**LearningContext**
- [ ] `update_strand`, `delete_strand` (need scope)
- [ ] `create_moment`, `update_moment`, `delete_moment`, `update_moments_positions` (need scope)
- [ ] `delete_moment_detaching_lessons`, `delete_moment_with_lessons` (already scoped)
- [ ] `create_strand` intentionally **not** guarded (new strand can't be locked yet)

**Assessments**
- [ ] `create/update/delete_assessment_point`, `delete_assessment_point_and_entries` (scoped)
- [ ] `update_assessment_points_positions`, `create_assessment_point_rubric` (need scope)
- [ ] entries: `create/update/delete_assessment_point_entry`, `save_assessment_point_entries` (need scope)
- [ ] evidence: `create_assessment_point_entry_evidence`, `update_..._positions` (need scope)

**Lessons**
- [ ] `create/update/delete_lesson`, `update_lessons_positions` (scoped)
- [ ] lesson_attachments fns (need scope)
- [ ] lesson_curriculum_items fns (mostly scoped; positions need scope)

**Strands**
- [ ] `create/update/delete_strand_curriculum_item` (+positions) (scoped)
- [ ] class_assignments fns (scoped)

**Excluded:** all `strand_report` functions (Reporting), lesson **tags**.

### Step 4 — UI / LiveView gating
- [ ] Lock/unlock control visible only to `strand_management` holders.
- [ ] Hide/disable edit affordances on locked strands for non-holders.
- [ ] Lock-state indicator on the strand.

### Step 5 — Tests
- [ ] Migration/schema: locked field defaults, lock changeset.
- [ ] Guard: locked strand blocks each mutation class; `strand_management` bypasses.
- [ ] Permission validation accepts `strand_management`.
- [ ] ExMachina factory: support `is_locked` in strand factory.

## Validation checklist (per CLAUDE.md)
`mix compile --warning-as-errors` · `mix deps.unlock --unused` · `mix format` ·
`mix credo --strict` · `mix test` (scoped).
