# Strand lock enforcement architecture

Status: accepted

## Context

A strand can be locked (`is_locked`) to freeze it and all its owned data for grading
integrity. We needed to decide *how* to enforce that freeze across ~70 mutation functions
spread over many contexts (LearningContext, Assessments, Lessons, Rubrics,
AssessmentComposition, Strands), and which writes the lock does and does not cover. The
choice is hard to reverse (it shapes every strand-owned mutation signature) and several
parts are surprising without the reasoning below.

## Decision

**Per-context guard, leaf `Strands`.** Each mutating context resolves the entity up to its
owning `strand_id` using the FK knowledge it already has, then calls a single
`Strands.ensure_strand_editable!(scope, strand_id)`. The guard only queries the `strands`
table for `is_locked`, so `Strands` stays a dependency-free leaf rather than a hub that
imports every nested schema. The three-way `AssessmentPoint → strand` resolution
(`strand_id | moment_id | lesson_id`) is extracted **once** as
`Assessments.strand_id_from_assessment_point/1` and reused by the entry, evidence,
composition-component, and AP-position paths so a lesson-level AP can't silently escape the
lock.

**Uniform `raise` on locked-without-permission**, mirroring the codebase's
`true = Scope.has_permission?(...)` style. The context guard is the backstop for any path the
UI misses (see the UI-gating decision below); it is not a substitute for it. The lock-state
race — a non-holder opens an edit form, the strand is then locked, they submit — is consciously
accepted as a rare crash rather than handled as a recoverable `{:error, :strand_locked}`.

**UI gating softens the raise — affordances are never hidden.** At the LiveView layer the
locked-out user must get a friendly message, not a 500, so the assessment/marking affordances
stay **visible**: each is either **disabled** (read-only) or left active with the action
**refused via a toast** (an `{:error, ...}`-style flash). Concretely — marking grid cells are
disabled (`EntryCellComponent.allow_edit`), the AP-reorder Sortable hook is not attached when
locked, and the AP create/edit/hide/composition buttons + grid command palette stay active but
their `handle_event` pre-checks a derived `can_edit_strand` boolean and toasts when locked. This
deliberately deviates from "hide what you can't do": hiding was rejected because threading a
`disabled`/visibility flag through a dozen buttons and the shared overlays is more churn than a
single derived boolean + a per-event pre-check, and because a visible-but-disabled control plus
a lock indicator explains *why* editing is blocked. A 🔒 lock indicator (badge + "Locked by X
on Y" from the provenance columns) is shown to **everyone** when the strand is locked, on staff
surfaces only — never on student/guardian surfaces.

**Bypass + lock authority is one permission, `strand_lock_management`** — named for what it
governs (toggle the lock + edit while locked), *not* a general strand-admin role. Ordinary
staff keep editing unlocked strands without it.

**Scope boundaries (the explicit no-s):**
- The composed-entry recalc Oban worker writes parent entries **directly via `Repo`** and is
  **intentionally not guarded** — a locked strand already blocks the component edits that
  would enqueue a recalc, and it is a system write of already-validated values.
- **Grade components** and **strand reports** are **excluded** — they belong to the
  report-card lifecycle, not strand-authored content, even though they reference an AP/strand.
- Personal/user-owned writes (starring, strand filters, AI chat) and school-owned lesson
  **tags** are excluded.

## Considered alternatives

- **Centralized resolvers in `Strands`** (`ensure_assessment_point_editable!`, …): rejected —
  it forces `Strands` to depend on half the app's schemas and risks circular dependencies.
- **Recoverable `{:error, :strand_locked}` for the lock-state race**: rejected for v1 in favor
  of a uniform `raise`; the race is rare and the extra plumbing wasn't judged worth it.

## Consequences

- Every guarded mutation gains (or already has) a `Scope` first argument; threading it into the
  previously scope-less entry functions touches their two LiveView callers.
- A holder's content edits to a locked strand are audited only where a `...Log` already exists
  (accepted, not widened).
- Lock provenance is stored twice for different jobs: denormalized `locked_at` /
  `locked_by_staff_member_id` on `strands` (cheap current state for the UI, keyed by
  staff member) and `StrandLog` (full history, keyed by `profile_id`).

## Update (issue #564): narrowed enforcement scope

The architecture above is unchanged, but the **set of guarded call sites was narrowed**. The
original "freeze everything strand-owned" reach (~70 functions across LearningContext,
Assessments, Lessons, Rubrics, AssessmentComposition, Strands) had a blast radius larger than
the actual need: *prevent teachers from changing assessment and marking after a report card is
shared with families*.

Enforcement is now limited to the writes that can change the **grade families saw**:

- **Assessment points** — CRUD + reorder (`update_assessment_points_positions`).
- **Assessment point entries (marking)** — CRUD + `save_assessment_point_entries`.
- **Composition structure** — `replace_assessment_point_components` + component CRUD. Included
  because restructuring composition recalcs the composed grade *without editing any entry*;
  editing a component entry is already covered (it is an entry).

Everything else strand-owned is **left editable while locked**: strand edit/delete, moments,
lessons (+ attachments, + lesson-curriculum-items), rubrics (+ descriptors, + AP↔rubric links),
strand curriculum items, class assignments, and entry **evidence** (it doesn't change the
numeric grade). The standing exclusions (strand reports, grade components, lesson tags, personal
mutations) are unchanged, as is the recalc-worker bypass.

Two consequences of the narrowing:
- `StrandLog` is wired into `lock_strand`/`unlock_strand` **only**, not strand CRUD — the narrow
  scope doesn't guard `create/update/delete_strand`, so threading `scope` through
  `StrandFormComponent` purely to log them isn't worth it.
- The three-way `strand_id_from_assessment_point/1` resolver is still extracted once and reused
  by the entry, composition-component, and AP-position paths (no longer the evidence path, which
  is now out of scope).

The **lock trigger is manual and reversible** — staff lock a strand when a report cycle is
shared, and a `strand_lock_management` holder can unlock it again (e.g. to let teachers fix a
generalized marking error found after sharing) and re-lock. Auto-lock-on-share was considered
and rejected as the intended workflow; both lock and unlock are deliberate human actions,
audited in `StrandLog`.
