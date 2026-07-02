# Plan (tracer bullets) — Issue #533: link assessment point to multiple lessons

Vertical-slice re-cut of
[`533-link-assessment-point-to-multiple-lessons.md`](533-link-assessment-point-to-multiple-lessons.md).
That plan is organized by horizontal layer (migration → schemas → contexts → UI →
tests); this one re-cuts the same work into **tracer-bullet slices** that each cut
through every layer end-to-end and land as an independently-verifiable increment.

The layer-by-layer plan remains the reference for file-level detail (which functions,
which fields, exact query shapes). Each slice below points into it rather than
repeating it.

## Why the slices are shaped this way

This is a data-model migration, and that constrains how thin the slices can be.
Dropping `assessment_points.lesson_id` forces **every consumer to move together** —
the `AssessmentPoint`/`AssessmentPointLog` schemas, four query paths in
`Lanttern.Assessments` (ownership/lock resolution, context filter, the `:lesson_id`
listing filter, and the student-entries report listing), the lesson-page write +
candidate UI, and the AP-card display all reference the column and stop compiling the
moment it's gone.

A strangler split that keeps `lesson_id` alive through a transition **does not work
here**: as soon as an AP can link to a second lesson, a single FK can't represent the
truth, so any read still resolving through `lesson_id` would silently drop
newly-linked APs (the exact bug the report listing would hit). So the many-to-many
foundation and all of its read paths must land in one tracer. What genuinely peels off
is (a) the dead-code prefactor before it, and (b) the AP-card display polish after it.

## Slice map & dependency order

| # | Slice | Blocked by | Demo |
|---|-------|-----------|------|
| 0 | Retire dead `classes` coupling (prefactor) | — | Green build/suite, no behavior change |
| 1 | M2M foundation + link/unlink multiple lessons from the lesson editor | 0 | Link one AP to two lessons; unlink one; works on a locked strand |
| 2 | AP-card lessons dropdown | 1 | AP card shows a lessons dropdown, each entry navigates |

Slice 0 is optional-but-recommended isolation; 1 depends on it only for a cleaner
`AssessmentPoint` schema and can technically be reordered. 2 strictly depends on 1.

---

## Slice 0 — Retire dead `classes` coupling (prefactor)

### Parent
Issue #533.

### What to build
Pure prefactor: remove the pre-strands `assessment_points_classes` coupling that is
already dead, so the `AssessmentPoint` schema is smaller before the model change lands.
No user-facing behavior changes.

Covers the "fold in cleanup" decision from the parent plan: drop the legacy
`assessment_points_classes` join table and every reference to the classes association
and its virtual fields on the assessment-point schema, plus the stray unused
classes preload in the assessment-point log. Leave the datetime and student/entry
legacy virtuals on `AssessmentPoint` **untouched** — they are out of scope.

Make the change easy first: this shrinks the schema and the fixture so Slice 1's edits
are smaller and less error-prone.

### Acceptance criteria
- [x] `assessment_points_classes` table dropped via migration (comment notes it is
      pre-strands legacy); migration is reversible.
- [x] `many_to_many :classes`, the `classes_ids` + never-cast singular `class_id`
      virtuals, `put_classes/1..2`, `:classes_ids` from cast, and the classes/class_id
      type entries removed from `AssessmentPoint`.
- [x] Stray unused `preload([:classes])` removed from `AssessmentPointLog`.
- [x] Any reverse `many_to_many :assessment_points` on `Schools.Class` verified and
      removed if present.
- [x] `classes_ids` dropped from `assessment_point_fixture`; the classes assertion in
      the assessments test deleted.
- [x] Datetime and student/entry legacy virtuals on `AssessmentPoint` left intact.
- [x] `mix compile --warning-as-errors`, `mix format`, `mix credo --strict`, and the
      scoped test suite all pass.

**Status: DONE** (commit `994c553c`).

### Blocked by
None — can start immediately.

---

## Slice 1 — Many-to-many foundation + link/unlink multiple lessons from the lesson editor

### Parent
Issue #533.

### What to build
The tracer bullet. Convert the assessment-point ↔ lesson link from a `belongs_to`
(`assessment_points.lesson_id`) into a **many-to-many** through a bare
`assessment_points_lessons` join table, and deliver the full linking experience on the
lesson editor page end-to-end: an assessment point can now be linked to **any number of
lessons**, linking is **additive** (never displaces an existing link), and unlinking
removes only this lesson's link.

Because dropping the column forces every consumer to move together, this slice
necessarily carries: the migration, both schemas, both audit-log schemas, all four
`Assessments` query paths that reference the old link (ownership/lock resolution,
context filter, the `:lesson_id` listing filter, and the student-entries report
listing), the new `Lessons` link/unlink API, and the lesson-page UI.

Key behaviors and decisions carried from the parent plan:

- **Bare join table**, no schema module, no ordering column. Linked APs always render
  by **moment position → AP position** (the AP's own moment, not the lesson's).
- **Only moment-owned APs are linkable** — every listing inner-joins the AP's moment,
  so a strand-level goal is deliberately dropped. Preserve this constraint.
- **Linking is lock-free.** Link/unlink does not change assessments/marking, so it must
  succeed on a **locked strand** — it must **not** call `ensure_strand_editable!`.
  Normal scope/permission guards still apply.
- **`Lessons` owns the link/unlink API** (the link is "lesson content"). Each toggle
  does a raw `insert_all(on_conflict: :nothing)` / `delete_all` against the join table,
  reloads the lesson, and writes one **lesson-log** row snapshotting the new
  `assessment_points_ids` set. The old per-AP `lesson_id` audit trail is intentionally
  dropped (retained in backups only).
- **Move-confirmation flow is deleted entirely** — linking is additive, so there is no
  displacement to confirm.
- The candidate list for a lesson is its strand's moment APs **not already linked to
  this lesson**.
- The student/guardian **report listing** must read through the join table and order by
  the AP's own moment, so an AP linked to two lessons groups identically in both
  lessons' report views (this is why it can't be deferred — a stale `lesson_id` read
  would silently drop newly-linked APs).

Data migration: backfill the join table from existing `lesson_id` values; the `down`
repopulates `assessment_points.lesson_id` from the join (min lesson per AP). Both FKs
`on_delete: :delete_all`, unique index on `(assessment_point_id, lesson_id)`. Drop
`log.assessment_points.lesson_id`; add `log.lessons.assessment_points_ids`. Use the
`db-migrations` skill. No sortable text columns, so no `und-x-icu` concerns.

The AP card must at minimum be updated to compile and not crash (its `:lesson` preload
and single-lesson render are gone) — a plain render of the linked lessons is acceptable
here; the polished dropdown is Slice 2.

### Acceptance criteria
- [x] `assessment_points_lessons` join table created (both FKs `on_delete: :delete_all`,
      unique `(assessment_point_id, lesson_id)`, FK indexes) and backfilled from
      existing `lesson_id`; migration `down` repopulates `lesson_id` from the join.
- [x] `assessment_points.lesson_id` (and its FK/index) dropped;
      `log.assessment_points.lesson_id` dropped; `log.lessons.assessment_points_ids`
      added.
- [x] `AssessmentPoint` exposes `many_to_many :lessons` **read/preload-only** (never
      cast/`put_assoc`); `Lesson` exposes `many_to_many :assessment_points`; logs
      updated (`AssessmentPointLog` loses `lesson_id`; `LessonLog` gains
      `assessment_points_ids`, mapped from preloaded `:assessment_points`).
- [x] `Assessments` no longer resolves ownership/lock/context via lesson; the
      `:lesson_id` listing filter and the student-entries report listing both join
      through `assessment_points_lessons`; `update_assessment_point` no longer touches
      lessons (keeps its lock guard for real edits).
- [x] `Lessons.link_assessment_point_to_lesson/3` and
      `unlink_assessment_point_from_lesson/3` exist, are idempotent (double-link no-ops
      via the unique index), succeed on a **locked strand**, and emit a lesson-log row
      with the `assessment_points_ids` snapshot.
- [x] On the lesson editor: linking an AP is **additive** (a second lesson link does
      not remove the first); the same AP appears in both lessons; unlinking removes only
      this lesson's link; the move-confirmation modal and its handlers are gone; the
      candidate list excludes APs already linked to this lesson; the linked list is
      ordered moment → AP position.
- [x] The student-entries report listing is ordered by the AP's own moment → AP
      position, and **one AP linked to two lessons appears in both lessons' listings**.
- [x] Existing `assessment_point_fixture(%{lesson_id: ...})` call sites converted to
      "create moment AP → link to lesson" via a small DRY test helper (minimal fixture
      edits only — no wholesale ExMachina migration).
- [x] Lesson-page view tests (`phoenix_test`): additive linking with **no** confirmation
      modal, and unlink removes only this lesson's link.
- [x] `mix compile --warning-as-errors`, `mix deps.unlock --unused`, `mix format`,
      `mix credo --strict`, and the scoped test suite all pass.

### Blocked by
- Slice 0 (recommended, for a clean `AssessmentPoint` schema and fixture). Otherwise
  none.

**Status: DONE.** Full suite green (1919 tests, 0 failures). One obsolete unit test
(`a lesson-level AP resolves through its lesson to the locked strand`) was removed —
lessons no longer participate in ownership/lock resolution, so a lesson-only AP now
correctly no-ops the guard (already covered by the "no owning strand" case). Added a
DRY `moment_assessment_point_linked_to_lesson_fixture/3` + bare
`link_assessment_point_to_lesson_fixture/2` in `AssessmentsFixtures`. The AP card
renders a minimal plain list of linked lessons; the polished dropdown is Slice 2.

---

## Slice 2 — AP-card lessons dropdown (display polish)

### Parent
Issue #533.

### What to build
On the assessment-point card in the strand assessment view, replace the plain
linked-lessons render from Slice 1 with a compact **link-icon button + dropdown menu**
that lists every lesson the AP is linked to, each a navigate link to that lesson,
ordered by lesson position. Display-and-navigate only — all link management stays on
the lesson page.

The button/dropdown renders only when the AP has at least one linked lesson.

### Acceptance criteria
- [ ] AP card renders a `size="xs"` link-icon button + `.dropdown_menu`, shown only when
      the AP has ≥1 linked lesson.
- [ ] The dropdown lists each linked lesson (ordered by lesson position) as a `navigate`
      link to that lesson's page; no link-management controls appear on the card.
- [ ] View test (`phoenix_test`): the dropdown lists multiple linked lessons and each
      navigates to its lesson.
- [ ] `mix compile --warning-as-errors`, `mix format`, `mix credo --strict`, and the
      scoped test suite all pass.

### Blocked by
- Slice 1.

---

## Out of scope (unchanged from the parent plan)

- AI-agent AP-linking tool (human UI only for now).
- Unlinking from the AP card (management lives entirely in the lesson view).
- Making strand goals linkable.
- Datetime/student legacy virtual-field cleanup on `AssessmentPoint`.
