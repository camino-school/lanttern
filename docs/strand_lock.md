# Strand Lock (`is_locked`) — Implementation Plan

Tracks issue **#564 — prevent strand changes**. Living document: update the
status checkboxes as commits land.

## Goal

Prevent teachers from changing **assessment and marking after a report card is shared
with families**. Concretely: add an `is_locked` flag to strands; when a strand is locked,
mutations to its **assessment points**, **assessment point entries (marking)**, and
**assessment-point composition structure** are blocked — **except** for users holding a new
`strand_lock_management` permission, who can edit those while locked and toggle the lock.

The lock is a **manual, permanent** action: staff with `strand_lock_management` lock a strand
when a report cycle is shared. There is no automatic lock-on-share hook.

**Scope narrowed (issue #564).** An earlier revision blocked *everything* strand-owned
(moments, lessons, rubrics, curriculum items, class assignments, …). The blast radius was
too large for the actual need, so enforcement is now limited to assessment points, entries,
and composition. Everything else strand-owned stays editable while locked. Steps 1/1b/2 (the
schema field, provenance, `StrandLog`, permission, lock toggle, and central guard) are
unchanged and already shipped; the broad Step 3 sweep + Step 4 UI gating were reverted and
re-planned below.

## Decisions (locked in)

- **Field name:** `is_locked` (matches the `is_`/`has_` boolean convention, e.g. `is_starred`).
- **Permission name:** `strand_lock_management` — named for what it governs (lock authority:
  toggle the lock + edit while locked), *not* a general strand-admin role. Ordinary staff
  still edit unlocked strands without it.
- **Lock scope (narrowed, issue #564):** blocks only **assessment points** (CRUD + reorder),
  **assessment point entries / marking** (CRUD + bulk save), and **composition structure**
  (`replace_assessment_point_components` + component CRUD). Everything else strand-owned stays
  editable while locked — see Excluded below.
- **Lock trigger:** **manual and permanent.** A `strand_lock_management` holder locks the strand
  (e.g. once a report cycle is shared). Auto-lock-on-report-share was considered and **rejected**
  as the intended workflow — the lock is a deliberate human action, not a lifecycle side effect.
- **Why composition is *in* but marking-adjacent data is *out*:** the goal is that the **grade
  families saw** can't change after sharing. Editing an entry changes it directly; editing a
  *component* entry changes it via recalc (also blocked — component entries *are* entries). But
  restructuring composition (weights / which components) recalcs the composed grade **without
  touching any entry**, so composition structure must be guarded too. Entry **evidence** and
  **AP↔rubric links** are *not* guarded — they don't change the numeric grade.
- **Strand reports:** **excluded** — governed by the report-card lifecycle, not the strand lock.
- **Grade components:** **excluded** — same reason as strand reports. A `grade_component`
  bridges an AP to a grades-report (`grades_report`/`_cycle`/`_subject`); it's report-card
  machinery that references an AP, not strand-authored content.
- **Lesson tags:** **excluded** — school-owned, not strand-owned.
- **Strand edit/delete: not guarded.** Editing strand details or deleting the strand is out of
  scope (neither is assessment/marking). A *populated* strand can't be deleted anyway —
  `Strand.delete_changeset/2` uses `no_assoc_constraint` on moments + assessment_points — and a
  strand whose report card was shared necessarily has assessment points, so there's no practical
  loss-of-graded-data path to worry about.
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
  Wired into `lock_strand`/`unlock_strand` only via `AuditLog.maybe_log(StrandLog, "UPDATE",
  scope, [])`. **Not** wired into `create/update/delete_strand` — under the narrow scope those
  aren't guarded, so threading `scope` through `StrandFormComponent` just to log them buys
  nothing; deferred. (The CHECK still permits CREATE/UPDATE/DELETE, so adding strand-CRUD
  logging later is a no-migration change.)
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
     entry, composition-component, and AP-position paths — never re-implemented (so a
     lesson-level AP can't silently escape the lock). A lesson-level AP resolves through its
     lesson to the owning strand, so its entries are locked just like a strand- or moment-level
     AP's.
   - For `create_*`, the owning id comes from **attrs** (e.g.
     `create_assessment_point` resolves from `strand_id|moment_id|lesson_id` in attrs) since
     there's no struct yet.
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
- [x] Migration `add_lock_provenance_to_strands`: `locked_at :utc_datetime` +
      `locked_by_staff_member_id` (FK → `staff`, `null: true`, `on_delete: :nothing` —
      matches Lanttern's defensive delete-blocking pattern) +
      index on `locked_by_staff_member_id` (applied).
- [x] `Strand` schema: added `locked_at`/`locked_by_staff_member_id` to schema + `@type t`;
      extended `lock_changeset/2` to stamp `locked_at` (+ keep caller-supplied
      `locked_by_staff_member_id`) on lock and clear both on unlock (still **not** in
      `changeset/2`).
- [x] `StrandLog` schema (`Lanttern.LearningContext.StrandLog`, `log`-prefixed) + migration
      `create_strands_log` following the `...Log` pattern; index on `strand_id`; `operation`
      CHECK; **no** `is_ai_agent`. `build_log_attrs/1` mirrors strand scalars incl. `is_locked`
      + `subjects_ids`/`years_ids`.
- [x] Validated: `mix compile --warning-as-errors`, `mix format`, `mix credo --strict`,
      `mix deps.unlock --unused`, `mix test test/lanttern/learning_context_test.exs`.

### Step 2 — Permission + context plumbing
- [x] Add `"strand_lock_management"` to `@valid_permissions` (`personalization.ex`) + moduledoc.
- [x] Add label to `@permission_to_option_map` (`personalization_helpers.ex`).
- [x] `Strands.lock_strand/2` & `unlock_strand/2` (permission-gated; set/clear provenance;
      `AuditLog.maybe_log(StrandLog, "UPDATE", …)`).
- [x] `Strands.strand_locked?/1` + `ensure_strand_editable!/2` central guard.
- [ ] ~~Wire `StrandLog` into `LearningContext.create/update/delete_strand`~~ **moved to Step 3.**
      These take no `scope` today; wiring `maybe_log` requires threading `current_scope`
      through the shared `StrandFormComponent` + delete sites — the same `scope` the Step 3
      guard needs. Done together there to avoid touching those call sites twice.
- [x] **Admin cleanup (extra):** removed the `/admin/strands` LiveViews
      (`admin/strand_live/{index,show}.{ex,heex}`), their routes, the admin-home nav link, and
      `admin/strand_live_test.exs`. Shrinks the `StrandFormComponent` render surface (now only
      the strands library + strand-show pages) ahead of the Step 4 scope plumbing.
- [x] Validated: `mix compile --warning-as-errors`, `mix format`, `mix credo --strict`,
      `mix deps.unlock --unused`, `mix test` (strands, personalization, admin_controller).

> **Note:** `LearningContext` is being phased out. **All new** strand-related functions
> (lock toggle, guard, `strand_locked?`) go in the **`Strands`** context. The guarded
> mutation functions (Assessments + AssessmentComposition only, under the narrow scope) stay
> where they are but call into `Strands.ensure_strand_editable!/2` for the guard.

### Step 3 — Enforcement sweep (narrow: assessment points, entries, composition)

Add the canonical resolver `Assessments.strand_id_from_assessment_point/1` (accepts an
`%AssessmentPoint{}` **or** an AP id; handles the three-way `strand_id|moment_id|lesson_id`;
returns `nil` for the no-strand edge) and give `Strands.ensure_strand_editable!/2` a `nil`
clause (no-op) so the leaf guard tolerates an AP that doesn't resolve to a strand. Thread
`%Scope{}` into the few entry call sites that lack it.

**Assessments** (resolve via `strand_id_from_assessment_point/1`)
- [ ] `create_assessment_point` (resolve `strand_id|moment_id|lesson_id` from **attrs**),
      `update_assessment_point`, `delete_assessment_point`, `delete_assessment_point_and_entries`
- [ ] `update_assessment_points_positions` (resolve from the first AP id; batch is single-strand)
- [ ] entries: `create_assessment_point_entry`, `update_assessment_point_entry`,
      `delete_assessment_point_entry`, `save_assessment_point_entries` (resolve per distinct AP,
      not per row; the grid batch is single-strand so the whole batch raises if locked)

**AssessmentComposition** (resolve via component → parent AP → strand)
- [ ] `create_assessment_point_component`, `update_assessment_point_component`,
      `delete_assessment_point_component`, `delete_all_assessment_point_components`,
      `replace_assessment_point_components` (the production save path — closes the composition
      grade-leak)
- [ ] `sync_strand_composed_entries` **intentionally NOT guarded** — recalc path
      (root-admin gated, idempotent, writes already-validated values via `Repo`); falls under
      the ADR recalc-bypass principle alongside `ComposedEntryRecalcWorker`.

**Call-site plumbing (production):**
- [ ] `EntryDetailsOverlayComponent` — plumb `current_scope` in (it only gets `current_user` today)
- [ ] `AssessmentsGridComponent` — `current_scope` already present; pass it at the entry-save call

**Out of scope (left editable while locked — do NOT guard):** strand edit/delete, moments,
lessons + attachments + lesson-curriculum-items, rubrics + descriptors + AP↔rubric links,
strand curriculum items, class assignments, entry **evidence**. Plus the standing exclusions:
all `strand_report` functions (Reporting), **grade components** (Grading), lesson **tags**, and
personal mutations (`star/unstar_strand`, `ProfileStrandFilter`, `StrandConversation`).

### Step 4 — UI / LiveView gating (narrow: assessment + marking surfaces)

**Model: two derived booleans + one indicator** (follows the existing
`@has_agents_management_permission` compute-once-in-`mount`-and-thread-down pattern):
- `@can_edit_strand` = `not strand.is_locked or has_lock_mgmt` → gates the **assessment**
  affordances only (add/edit/delete/reorder APs, the composition overlay's save, and the
  marking grid cells via the existing `EntryCellComponent` `allow_edit` attr).
- `@has_strand_lock_management` = `has_lock_mgmt` → gates the **lock/unlock control itself**,
  *independent of lock state* (must show "Lock" when unlocked, "Unlock" when locked — so it
  can't be folded into `@can_edit_strand`).
- **Lock indicator** (🔒 badge + "Locked by X on Y" from the provenance columns) → shown to
  **everyone** when `strand.is_locked`; no permission needed (explains *why* edits are hidden).
  Implement as a `LearningContextComponents.strand_lock_bar/1` (top-bar variant) plus a
  `strand_card` overlay badge; both call a shared `lock_provenance_text/2` helper.

**Surfaces (narrow — only where assessment/marking is mutated):**
- [ ] Strand show `strand_live.ex` → compute both booleans in `mount` (`assign_strand_lock/1`);
      thread `@can_edit_strand` into the **Assessment tab only** (`assessment_component`), which
      gates AP create/edit/delete buttons, disables the Sortable reorder hook, gates the
      composition overlay save, and sets the grid cells' `allow_edit`. Overview/Lessons/Rubrics
      tabs are **not** gated.
- [ ] Marking route `marking_live.ex` → compute `@can_edit_strand`, pass into
      `AssessmentsGridComponent` as `can_edit` → reuses `EntryCellComponent.allow_edit`. Add the
      lock bar (preload `:locked_by_staff_member` for provenance text).
- [ ] Lock/unlock control + indicator in the strand header (`strand_live`): `toggle_lock` event
      gated by `@has_strand_lock_management` + confirm-dialog menu item; indicator via
      `strand_lock_bar` in the header `:top_bar` slot.
- [ ] 🔒 badge on **staff** strand-browse surfaces (library, `/strands`, dashboard) via the
      `strand_card` overlay (`show_lock`, default `false`; enable only on these staff surfaces;
      **never** on student/guardian surfaces). Preload `:locked_by_staff_member` for full text.
- [ ] Context `raise` remains the backstop for any affordance the UI sweep misses — not a
      substitute for it.

### Step 5 — Tests (narrow)
- [ ] Migration/schema: `is_locked` default; lock changeset sets/clears `locked_at` +
      `locked_by_staff_member_id`; `is_locked`/provenance **not** castable via `changeset/2`.
- [ ] `lock_strand`/`unlock_strand`: permission-gated (holder ok, non-holder raises);
      idempotent (locking an already-locked strand re-stamps provenance, doesn't error);
      each writes a `StrandLog` `"UPDATE"` row.
- [ ] Guard: locked strand blocks the **in-scope** mutation classes — APs (CRUD + reorder),
      entries (CRUD + bulk save), and composition components (CRUD + `replace_…`);
      `strand_lock_management` bypasses all.
- [ ] **Resolution**: lesson-level *and* moment-level *and* strand-level APs each resolve to
      the right strand (the three-way branch) — a lesson-level AP must not escape the lock.
- [ ] **Out-of-scope paths stay editable when locked:** strand edit/delete, moments, lessons +
      attachments + lesson-curriculum-items, rubrics + descriptors + AP↔rubric links, strand
      curriculum items, class assignments, entry **evidence**; plus strand reports, grade
      components, lesson tags, and the personal mutations.
- [ ] Recalc worker write path is unaffected by the lock (system write via `Repo`).
- [ ] `StrandLog`: lock/unlock produce `"UPDATE"` rows with correct `profile_id`/`is_locked`;
      no `is_ai_agent` column. (No strand-CRUD logging under the narrow scope.)
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
