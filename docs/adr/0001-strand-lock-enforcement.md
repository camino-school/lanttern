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
`true = Scope.has_permission?(...)` style. The UI hides affordances up front (defense in
depth); the guard is the backstop. The lock-state race — a non-holder opens an edit form,
the strand is then locked, they submit — is consciously accepted as a rare crash rather than
handled as a recoverable `{:error, :strand_locked}`.

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
