# Plan — Issue #533: link assessment point to multiple lessons

## Goal

Convert the assessment-point ↔ lesson **link** (currently `assessment_points.lesson_id`,
a `belongs_to`) into a **many-to-many**, so the same assessment point can be linked to
any number of lessons — better reflecting continuous/processual assessment across
several lessons.

## Key decisions (from design review)

- **Bare join table** `assessment_points_lessons` (no schema module, no extra columns).
  Ordering is never stored on the link — linked APs always render by **moment position →
  AP position**, following the AP's own position for consistency.
- **Only moment-owned APs are linkable** (strand-level "goal" APs are not). Every listing
  query inner-joins the AP's moment; a linked strand goal would be silently dropped, so
  this constraint is preserved deliberately.
- **Linking is lock-free.** Linking/unlinking an AP to a lesson does not change
  assessments/marking (the operation the strand lock protects), so it must be allowed on
  locked strands. Link/unlink therefore does **not** call `Strands.ensure_strand_editable!`.
- **`Lessons` owns the link/unlink API** — the link is conceptually "lesson content."
  Auditing goes through the **lesson log** via a new `assessment_points_ids` array column.
- **Fold in cleanup** of the dead pre-strands `assessment_points_classes` table
  (classes-only; no collateral to the datetime/student legacy virtuals).

## 1. Migration(s) — use the `db-migrations` skill

- Create `assessment_points_lessons`: `assessment_point_id`, `lesson_id`, timestamps;
  index on each FK; **unique index on `(assessment_point_id, lesson_id)`**; both FKs
  **`on_delete: :delete_all`** (mirrors `lesson_curriculum_items`; deleting a lesson or AP
  cleans up its links — preserves today's `:nilify_all` net effect without blocking deletes).
- **Backfill**: `INSERT INTO assessment_points_lessons (...) SELECT id, lesson_id, now(), now()
  FROM assessment_points WHERE lesson_id IS NOT NULL`. Reversible `down` repopulates
  `assessment_points.lesson_id` from the join (min lesson per AP).
- Drop `assessment_points.lesson_id` (its FK + index go with it).
- Drop legacy `assessment_points_classes` table (comment: pre-strands legacy join).
- Drop `log.assessment_points.lesson_id` (comment: intentional data loss — link history now
  lives in the lesson log; old values retained in backups only).
- Add `assessment_points_ids {:array, :integer}` to `log.lessons`.

No sortable text columns are added, so no `und-x-icu` collation concerns.

## 2. Schemas

- **`AssessmentPoint`** (`lib/lanttern/assessments/assessment_point.ex`):
  - Drop `belongs_to :lesson` + `lesson_id` (type, schema, `:lesson_id` from cast).
  - Add `many_to_many :lessons, Lesson, join_through: "assessment_points_lessons"` —
    **read/preload only, never cast** (linking is managed by raw insert/delete in `Lessons`,
    not `put_assoc`).
  - Remove `many_to_many :classes`, the `classes_ids` + never-cast singular `class_id`
    virtuals, `put_classes/1..2`, `:classes_ids` from cast, and the classes/class_id type
    entries. **Leave the datetime (`date/hour/minute`, `validate_and_build_datetime`) and
    student/entry (`student_id/students_ids/student_entry/has_diff_rubric_for_student/
    cast_entries`) virtuals untouched.**
- **`Lesson`** (`lib/lanttern/lessons/lesson.ex`): `has_many :assessment_points` →
  `many_to_many :assessment_points, AssessmentPoint, join_through: "assessment_points_lessons"`.
- **`AssessmentPointLog`** (`lib/lanttern/assessments/assessment_point_log.ex`): remove the
  `:lesson_id` field/cast/`build_log_attrs` mapping; delete the stray unused
  `preload([:classes])`.
- **`LessonLog`** (`lib/lanttern/lessons/lesson_log.ex`): add `assessment_points_ids` field +
  cast; `build_log_attrs/1` preloads `:assessment_points` and maps
  `Enum.map(lesson.assessment_points, & &1.id)`.
- Verify/remove any reverse `many_to_many :assessment_points` on `Schools.Class`.

## 3. Context — `Lanttern.Lessons`

- `link_assessment_point_to_lesson/3` and `unlink_assessment_point_from_lesson/3`:
  - Raw `Repo.insert_all("assessment_points_lessons", [...], on_conflict: :nothing)` /
    `Repo.delete_all(from j in "assessment_points_lessons", where: ...)`.
  - Then reload the lesson and `AuditLog.maybe_log(LessonLog, "UPDATE", scope, ...)` (one
    log row per toggle; the `assessment_points_ids` snapshot captures the before/after set).
  - **No `ensure_strand_editable!`** — works on locked strands. Normal scope/permission
    guard still applies. Human-UI only for now (no AI-agent path).

## 4. Context — `Lanttern.Assessments`

- Drop the `lesson_id` branch from `strand_id_from_assessment_point/1` **and**
  `filter_assessment_points_by_context/2` — lesson no longer participates in ownership,
  lock resolution, or creation position. Ownership resolves purely via `strand_id`/`moment_id`.
- `update_assessment_point/3` stops touching lessons (keeps its lock guard for real edits).
- Rewrite `apply_assessment_points_filter({:lesson_id, id})` to join through
  `assessment_points_lessons` (unique pair index ⇒ no dupes).
- Rewrite `list_lesson_assessment_points_with_student_entries/3`: join through the join
  table; change the order join from the **lesson's** moment to the **AP's own** moment
  (`join: m in assoc(ap, :moment)`, `order_by: [asc: m.position, asc: ap.position]`) so the
  student/guardian report view groups linked APs identically to the lesson editor.

## 5. UI — lesson page (`lib/lanttern_web/live/pages/strands/lesson/id/lesson_live.ex` + `.heex`)

- **Delete the "move link" confirmation flow entirely**: `unlinking_from_lesson`,
  `linking_to_assessment_point`, `confirm_assessment_point_link`,
  `cancel_assessment_point_link`, and the confirmation modal in the heex. Linking is now
  additive — it never displaces an existing link.
- `link_assessment_point` / `unlink_assessment_point` → call the new `Lessons` functions,
  then re-stream.
- Candidate list (`load_strand_assessment_points`): strand's moment APs **not already linked
  to this lesson** (track the linked AP-id set in assigns; replaces the old
  `&1.lesson_id != lesson.id` filter).
- Linked-AP stream ordered by moment → AP position.

## 6. UI — AP card (`lib/lanttern_web/live/pages/strands/id/assessment_component.ex`)

- `@ap_preloads`: `:lesson` → `:lessons`.
- Replace the single `Lesson: {name}` link with a `size="xs"` link-icon **button +
  `.dropdown_menu`**, rendered only when `lessons != []`, listing each linked lesson as a
  `navigate` link to `~p"/strands/lesson/#{lesson}"` (ordered by lesson position).
- **Display + navigate only** — all link management stays on the lesson page.

## 7. Tests

- **`Lessons` context**: `link/unlink` idempotency (double-link no-ops via unique index),
  **lock-bypass** (linking succeeds on a locked strand), lesson-log `assessment_points_ids`
  snapshot emitted.
- **`Assessments` queries**: both listings ordered by moment → AP position; **one AP linked
  to two lessons appears in both lessons' listings** (core many-to-many guarantee).
- **Rewrite existing blocks**: `assessment_point_fixture(%{lesson_id: ...})` sites become
  "create moment AP → link to lesson" via a small DRY test helper. Drop `classes_ids` from
  `assessment_point_fixture`; delete the `assessments_test.exs:264` classes assertion.
- **View tests (`phoenix_test`)**: lesson page — additive linking with **no** confirmation
  modal, and unlink removes only this lesson's link; AP card — dropdown lists multiple
  linked lessons and each navigates.
- Minimal fixture edits only — **no** wholesale ExMachina migration of the fixture file.

## Out of scope

- AI-agent AP-linking tool (human UI only for now).
- Unlinking from the AP card (management lives entirely in the lesson view).
- Making strand goals linkable.
- Datetime/student legacy virtual-field cleanup on `AssessmentPoint`.

## Validation

`mix compile --warning-as-errors`, `mix deps.unlock --unused`, `mix format`,
`mix credo --strict`, and scoped `mix test`.
