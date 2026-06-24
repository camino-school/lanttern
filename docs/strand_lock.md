# Strand Lock (`is_locked`) — Implementation Plan

Tracks issue **#564 — prevent strand changes**. Living document: update the
status checkboxes as commits land.

## Goal

Add an `is_locked` flag to strands. When a strand is locked, **all** mutations to
the strand and its related data (moments/lessons, assessment points, grade
entries/markings, etc.) are blocked — **except** for users holding a new
`strand_lock_management` permission, who can both edit locked strands and toggle the
lock.

## Decisions (locked in)

- **Field name:** `is_locked` (matches the `is_`/`has_` boolean convention, e.g. `is_starred`).
- **Permission name:** `strand_lock_management` — named for what it governs (lock authority:
  toggle the lock + edit while locked), *not* a general strand-admin role. Ordinary staff
  still edit unlocked strands without it.
- **Lock scope:** blocks **everything** strand-owned, **including grade entries (markings)**.
- **Strand reports:** **excluded** — governed by the report-card lifecycle, not the strand lock.
- **Grade components:** **excluded** — same reason as strand reports. A `grade_component`
  bridges an AP to a grades-report (`grades_report`/`_cycle`/`_subject`); it's report-card
  machinery that references an AP, not strand-authored content.
- **Lesson tags:** **excluded** — school-owned, not strand-owned.
- **Deleting a locked strand:** a `strand_lock_management` holder **may delete it directly**
  (no unlock-first step); the guard already yields this. Safe because there is **no cascade** —
  `Strand.delete_changeset/2` uses `no_assoc_constraint` on moments + assessment_points, so a
  populated strand can't be deleted until its children are removed, and each child delete is
  itself lock-guarded. Accidental one-click loss of a locked, populated strand is therefore
  effectively impossible. (Confirm dialog should still note the strand is locked.)
- **Personal/user-owned excluded:** `star/unstar_strand`, `ProfileStrandFilter` mutations,
  `StrandConversation` (AI chat) — these are per-user state, not strand content.
- **Failure mode:** **raise** on locked-without-permission (consistent with the codebase's
  `true = Scope.has_permission?(...)` style). UI hides affordances so it's defense-in-depth.
  The lock-state race (strand locked after a non-holder opened an edit form, then submits)
  is **consciously accepted** as a rare crash — not handled as a recoverable `{:error, ...}`.
- **Lock provenance (on `strands`):** add `locked_at :utc_datetime` and
  `locked_by_staff_member_id` (FK → staff_member). Denormalized *current* provenance, O(1)
  for the Step 4 indicator and joinable to the staff member's name. Set in the lock-only
  changeset from `Scope`; cleared on unlock.
- **`StrandLog` audit table:** add a `log`-prefixed `strands` log following the existing
  `...Log` pattern (`@behaviour Lanttern.AuditLog`, `build_log_attrs/1`, `operation` CHECK
  CREATE/UPDATE/DELETE, `profile_id`, `timestamps(updated_at: false)`, index on `strand_id`).
  Wired into `create/update/delete_strand` and `lock_strand`/`unlock_strand` via
  `AuditLog.maybe_log(StrandLog, op, scope, [])`. (Reverses the earlier "no audit-log mirror"
  note.)
  - Lock/unlock log as **`"UPDATE"`** with `is_locked` captured in the snapshot — no custom
    operation string.
  - **No `is_ai_agent`** column: strand lock/CRUD has no AI-agent write path, so it would
    always be `false`. Add later only if such a path threads the `:is_ai_agent` opt.
  - `build_log_attrs/1` mirrors the strand's scalar fields incl. `is_locked` (+ `subjects_ids`,
    `years_ids`); it does **not** re-capture `locked_at`/`locked_by` — the log's own
    `inserted_at`/`profile_id` are the authoritative who/when for each row.
- **Provenance vs log are complementary:** strand columns = cheap *current* state keyed by
  `staff_member_id` (for the UI); `StrandLog` = full *history* keyed by `profile_id` (audit).

## Architecture

1. **`strands.is_locked`** — real `:boolean`, `null: false, default: false`.
   **Not castable** in `Strand.changeset/2` so content edits can never flip the lock.
2. **Lock toggle** — dedicated `lock_strand/2` & `unlock_strand/2` in the **`Strands`**
   context (`lib/lanttern/strands.ex`), each gated by
   `true = Scope.has_permission?(scope, "strand_lock_management")`, using a lock-only changeset
   that also sets/clears `locked_at` + `locked_by_staff_member_id` from `Scope`, and pipes
   through `AuditLog.maybe_log(StrandLog, "UPDATE", scope, [])`.
3. **Central guard** — `Strands.ensure_strand_editable!(scope, strand_id)`:
   ```elixir
   if strand_locked?(strand_id) and not Scope.has_permission?(scope, "strand_lock_management"),
     do: raise(...)
   ```
   Called at the top of every strand-owned mutation after resolving the owning `strand_id`.
4. **Strand resolution (per-context; guard stays a leaf).** The guard
   `Strands.ensure_strand_editable!(scope, strand_id)` only queries the `strands` table —
   `Strands` never learns about APs/entries/moments/lessons. Each context resolves
   entity→`strand_id` with the FK knowledge it already has, then calls the guard.
   - The **AP→strand** hop (three-way `strand_id | moment_id | lesson_id`) is extracted
     **once** as canonical `Assessments.strand_id_from_assessment_point/1` and reused by the
     entry, evidence, composition-component, and AP-position paths — never re-implemented
     (so a lesson-level AP can't silently escape the lock).
   - For `create_*`, the owning id comes from **attrs** (e.g. `create_moment` reads
     `strand_id`; `create_assessment_point` resolves from `strand_id|moment_id|lesson_id` in
     attrs) since there's no struct yet.
   - Bulk `save_assessment_point_entries` resolves distinct APs once, not per-row; a grid
     batch is **single-strand** (the grid is scoped to one strand/moment), so the whole batch
     raises if that strand is locked.
5. **Recalc worker bypass (intentional).** The composed-entry recalc path
   (`ComposedEntryRecalcWorker` → `AssessmentComposition.recalculate_composed_entries`)
   writes parent entries **directly via `Repo`**, not through the guarded mutation
   functions — so it is **not** lock-guarded, by design: a locked strand already blocks
   the *component* entry edits that would enqueue a recalc, and the worker is a system
   write of already-validated values. Guarding it would force a system action to
   re-derive permissions for no benefit.
6. **Entry-mutation call sites.** Only two production callers thread into the guarded
   entry functions: `EntryDetailsOverlayComponent` (needs `current_scope` plumbed in —
   it only gets `current_user` today) and `AssessmentsGridComponent` (`current_scope`
   already present, currently unused at the call). `delete_assessment_point_entry` has
   no production caller.

## Steps

### Step 1 — Migration + schema field ✅ (extended below)
- [x] Migration: `add_is_locked_to_strands` — `is_locked :boolean, null: false, default: false` (applied).
- [x] `Strand` schema: `field :is_locked, :boolean, default: false`, added to `@type t`.
- [x] Kept `is_locked` **out** of `Strand.changeset/2` cast list.
- [x] Added lock-only changeset `Strand.lock_changeset/2`.
- [x] Validated: `mix compile --warning-as-errors`, `mix format`.

### Step 1b — Provenance columns + `StrandLog` (new, from grilling)
- [ ] Migration: add `locked_at :utc_datetime` + `locked_by_staff_member_id` (FK → staff_member,
      `null: true`) to `strands`. Use the `db-migrations` skill.
- [ ] `Strand` schema: add the two fields to schema + `@type t`; extend `lock_changeset/2` to
      set them on lock and clear them on unlock (still **not** in `changeset/2`).
- [ ] `StrandLog` schema (`log`-prefixed) + migration following the `...Log` pattern; index on
      `strand_id`; `operation` CHECK; **no** `is_ai_agent`. `build_log_attrs/1` mirrors strand
      scalars incl. `is_locked` + `subjects_ids`/`years_ids`.

### Step 2 — Permission + context plumbing
- [ ] Add `"strand_lock_management"` to `@valid_permissions` (`personalization.ex`).
- [ ] Add label to `@permission_to_option_map` (`personalization_helpers.ex`).
- [ ] `Strands.lock_strand/2` & `unlock_strand/2` (permission-gated; set/clear provenance;
      `AuditLog.maybe_log(StrandLog, "UPDATE", …)`).
- [ ] `Strands.strand_locked?/1` + `ensure_strand_editable!/2` central guard.
- [ ] Wire `StrandLog` into `LearningContext.create/update/delete_strand`
      (`AuditLog.maybe_log(StrandLog, "CREATE"/"UPDATE"/"DELETE", scope, [])`).

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
- [ ] lesson_attachments fns: `create_lesson_attachment`, `update_lesson_attachments_positions`,
      `toggle_lesson_attachment_share` (need scope)
- [ ] lesson_curriculum_items fns (mostly scoped; positions need scope)

**Strands**
- [ ] `create/update/delete_strand_curriculum_item` (+positions) (scoped)
- [ ] class_assignments fns (scoped)

**Rubrics** (resolve via `rubric.strand_id`; assessment rubrics only)
- [ ] `create/update/delete_rubric`, `update_rubrics_positions` (need scope)
- [ ] `create/update/delete_rubric_descriptor` (resolve via descriptor → rubric → strand) (need scope)

**AssessmentComposition** (resolve via component → parent AP → strand)
- [ ] `create/update/delete_assessment_point_component`, `delete_all_assessment_point_components` (scoped)
- [ ] `sync_strand_composed_entries` (scoped)

**Excluded:** all `strand_report` functions (Reporting), **grade components** (Grading —
report-card lifecycle), lesson **tags**, and personal mutations (`star/unstar_strand`,
`ProfileStrandFilter`, `StrandConversation`).

### Step 4 — UI / LiveView gating

**Model: two derived booleans + one indicator** (follows the existing
`@has_agents_management_permission` compute-once-in-`mount`-and-thread-down pattern):
- `@can_edit_strand` = `not strand.is_locked or has_lock_mgmt` → gates **content** affordances
  (edit details; add/edit/delete/reorder moments·lessons·APs·rubrics·curriculum-items·class-
  assignments; grid cells via the existing `EntryCellComponent` `allow_edit` attr).
- `@has_strand_lock_management` = `has_lock_mgmt` → gates the **lock/unlock control itself**,
  *independent of lock state* (must show "Lock" when unlocked, "Unlock" when locked — so it
  can't be folded into `@can_edit_strand`).
- **Lock indicator** (🔒 badge + "Locked by X on Y" from the provenance columns) → shown to
  **everyone** when `strand.is_locked`; no permission needed (explains *why* edits are hidden).

**Surfaces (compute the booleans on every page that mutates strand-owned data — the parent
strand, with `is_locked`, is already loaded on each, so it's free):**
- [ ] Strand show `strand_live.ex` → thread `@can_edit_strand` into the 4 tab components
      (Overview, Lessons, Rubrics, Assessment); reuse `EntryCellComponent.allow_edit`.
- [ ] Standalone lesson page `strands/lesson/id/lesson_live.ex` (already assigns `@strand`).
- [ ] Any other standalone moment / assessment-point edit route (audit during impl).
- [ ] Lock/unlock control + indicator in the strand header (where "Edit strand"/menu live).
- [ ] Context `raise` remains the backstop for any affordance the UI sweep misses — not a
      substitute for it.

### Step 5 — Tests
- [ ] Migration/schema: `is_locked` default; lock changeset sets/clears `locked_at` +
      `locked_by_staff_member_id`; `is_locked`/provenance **not** castable via `changeset/2`.
- [ ] `lock_strand`/`unlock_strand`: permission-gated (holder ok, non-holder raises);
      idempotent (locking an already-locked strand re-stamps provenance, doesn't error);
      each writes a `StrandLog` `"UPDATE"` row.
- [ ] Guard: locked strand blocks **each** mutation class (moments, lessons + attachments +
      curriculum-items, APs, entries, evidence, rubrics + descriptors, composition components,
      strand curriculum items, class assignments); `strand_lock_management` bypasses all.
- [ ] **Resolution**: lesson-level *and* moment-level *and* strand-level APs each resolve to
      the right strand (the three-way branch) — a lesson-level AP must not escape the lock.
- [ ] Excluded paths stay editable when locked: strand reports, grade components, lesson tags,
      `star/unstar_strand`, `ProfileStrandFilter`, `StrandConversation`.
- [ ] Recalc worker write path is unaffected by the lock (system write via `Repo`).
- [ ] `StrandLog`: create/update/delete + lock/unlock produce rows with correct
      `operation`/`profile_id`/`is_locked`; no `is_ai_agent` column.
- [ ] Permission validation accepts `strand_lock_management`.
- [ ] ExMachina factory: support `is_locked` (+ provenance) in strand factory.

## Resolved during grilling (smaller items)
- **Holder edits-while-locked accountability:** **accepted as-is** — a holder's content edits to
  a locked strand are logged only where a `...Log` already exists. We will **not** widen logging
  for now.
- **`strand_lock_management` provisioning:** just another checkbox in the existing permission
  admin UI (no auto-grant / special role).
- **Lock-control UI placement/wording:** deferred to the Step 4 commit.

See `docs/adr/0001-strand-lock-enforcement.md` for the enforcement-architecture rationale.

## Validation checklist (per CLAUDE.md)
`mix compile --warning-as-errors` · `mix deps.unlock --unused` · `mix format` ·
`mix credo --strict` · `mix test` (scoped).
