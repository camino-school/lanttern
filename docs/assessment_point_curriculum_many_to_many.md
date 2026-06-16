# Impact Map — `AssessmentPoint` ↔ curriculum_item (optional + many-to-many)

**Status:** Planned, not started. Mapped 2026-06-16. Out of scope for the
current assessment-point work — tracked here for a future, dedicated commit.

## Background

As of commit `c990eed1` (`feat(assessments): require assessment point name and
drop curriculum fallback`), `AssessmentPoint.name` is `NOT NULL`. That was step
one toward a larger relationship change:

- **(A)** `assessment_points.curriculum_item_id` becomes **nullable** (optional).
- **(B)** the AP ↔ curriculum_item relationship becomes **many-to-many** (an
  assessment point can reference many curriculum items, or none).

The two parts break different code:

- **A** breaks every **INNER JOIN** on the assoc (silently drops AP rows) and
  any unguarded `ap.curriculum_item.*` dereference.
- **B** breaks the singular `belongs_to` assumption, the
  `[:strand_id, :curriculum_item_id]` unique constraint, the denormalized
  `curriculum_item_name` / `curriculum_component_name` composition fields, the
  audit log, and the single-select curriculum picker UI.

---

## 1. Schema & database (the root)

| File | What | Affected by |
|---|---|---|
| `lib/lanttern/assessments/assessment_point.ex:84` | `belongs_to :curriculum_item` | B — becomes `many_to_many` (new join table) |
| `lib/lanttern/assessments/assessment_point.ex:133` | `validate_required([:name, :curriculum_item_id, :scale_id])` | A — drop `:curriculum_item_id` |
| `lib/lanttern/assessments/assessment_point.ex:138-140` | `unique_constraint([:strand_id, :curriculum_item_id])` ("Curriculum item already added to this strand") | A+B — NULLs aren't unique in PG; M-to-M removes the pair |
| `lib/lanttern/assessments/assessment_point.ex:41` | `@type curriculum_item_id: pos_integer()` | A — add `| nil` |
| `priv/repo/migrations/20230803153019_create_assessment_points.exs:9` | `add :curriculum_item_id, …, null: false` | A — drop NOT NULL |
| `priv/repo/migrations/20240112204922_add_strand_id_to_assessment_points.exs:9` | `create unique_index([:strand_id, :curriculum_item_id])` | A+B — drop |
| `lib/lanttern/assessments/assessment_point_log.ex:73` | logs `curriculum_item_id` | B — audit-log table mirrors the column; the join needs its own logging story (see audit-log rule in CLAUDE.md) |

**No `assessment_points_curriculum_items` join table exists** — B needs a new
migration + backfill from the existing column. Any new sortable text column
(none expected here) would need the `und-x-icu` collation per CLAUDE.md.

---

## 2. Context queries — INNER JOIN on curriculum_item (part A: silently drop rows)

All do `join: ci in assoc(ap, :curriculum_item)` + `join: cc in assoc(ci, :curriculum_component)`.
Once `curriculum_item_id` can be NULL, the inner join **excludes those APs**.

- `lib/lanttern/assessments.ex` — `:774`, `:819`, `:1096`, `:1140`, `:1186`
  (list_strand_*, list_lesson_* with student entries; several rebuild the AP
  struct inside `select:`, so they need extra care, not just join → left_join)
- `lib/lanttern/grades_reports.ex` — `:706`, `:757`, `:1019`, `:1085`, `:1158`
  (grade composition listing + all `calculate_*` paths)
- `lib/lanttern/rubrics.ex` — `:115`, `:263`
- `lib/lanttern/reporting.ex` — `:1402`
- `lib/lanttern/dataviz.ex` — `:54-61`

---

## 3. Composition / grades data model (part B)

The "Curriculum" column in `grade_composition_table` is fed by **persisted,
denormalized** fields. Open question: with many curriculum items per AP, what
goes in that single cell?

- `lib/lanttern/grades_reports.ex:961-982` — `build_comp_component/4` writes
  singular `curriculum_item_id/name`, `curriculum_component_id/name` from
  `metadata.curriculum_item`.
- `lib/lanttern/grades_reports/student_grades_report_entry.ex:66-69` & `:113-130`
  — embedded composition schema **stores** those singular fields; historical
  records exist, so a change touches existing data.
- `lib/lanttern_web/components/grades_reports_components.ex:1106` — render site
  (`grade_composition_table`).

---

## 4. Rubric coupling (part B — subtle, high-risk)

Rubrics are matched to APs **by shared `curriculum_item_id`**, which breaks once
an AP has many (or none).

- `lib/lanttern/rubrics/rubric.ex:26-27,43` — `Rubric` itself has
  `belongs_to :curriculum_item` + required.
- `lib/lanttern/rubrics.ex:111,123,181,252,271` — group/filter APs by
  `ap.curriculum_item_id`; `list_assessment_point_rubrics/2` filters
  `r.curriculum_item_id == ap.curriculum_item_id`.
- `lib/lanttern_web/live/shared/rubrics/rubric_form_overlay_component.ex:77-115`
  — UI copy: "Rubrics can be linked to assessment points with matching
  curriculum item."

---

## 5. Reporting / dataviz that assume 1:1

- `lib/lanttern/reporting.ex:1303` — joins parent goals
  `on: pg.curriculum_item_id == ap.curriculum_item_id` (evidence linking).
- `lib/lanttern/dataviz.ex:89,120` — `Enum.map(& &1.curriculum_item)` /
  `& &1.curriculum_item_id`, one per AP.

---

## 6. Web rendering of `ap.curriculum_item.*` (part A nil-safety + part B "which item")

Templates dereferencing the singular assoc; all carry
`curriculum_item: :curriculum_component` preloads that become `curriculum_items: …`.

- `lib/lanttern_web/live/shared/assessments/entry_details_overlay_component.ex:36,41` (preload `:572`)
- `lib/lanttern_web/live/shared/assessments/student_assessment_point_details_overlay_component.ex:100-112` (preload `:141-145`, also `:subjects`)
- `lib/lanttern_web/live/pages/strands/id/assessment_component.ex:361,364` (preload `@ap_preloads:18`)
- `lib/lanttern_web/live/pages/strands/lesson/id/lesson_live.ex:61,64` (preloads `:134`, `:155`)
- `lib/lanttern_web/live/shared/grading/grade_composition_view_overlay_component.ex:84,89`
- `lib/lanttern_web/live/pages/shared/strand_report/strand_report_rubrics_component.ex:62,64`
- `lib/lanttern_web/live/pages/strands/id/strand_rubrics_component.ex:49,51,122,124`
- `lib/lanttern_web/live/shared/assessment_composition/assessment_point_composition_overlay_component.ex` — `@ap_preloads:25`, helper at `:192` builds `(component) item`
- `lib/lanttern_web/live/shared/assessments/assessments_grid_component.ex:810,846,1260` (three preload sites)

---

## 7. Forms — single-select → multi-select (part B)

- `lib/lanttern_web/live/shared/assessments/assessment_point_form_overlay_component.ex`
  — `:87-94`/`:115` hidden single `curriculum_item_id` via
  `CurriculumItemSearchComponent`; handlers `:233-254` (select), `:361-383`
  (remove). Main UX redesign.
- Strand goal form (same overlay) and the command palette flow inherit this.

---

## 8. Tests, factory, fixtures

- `test/support/factories/assessment_point_factory.ex:10-16` — always
  `build(:curriculum_item)`.
- `test/support/fixtures/assessments_fixtures.ex:18,81` —
  `maybe_gen_curriculum_item_id/1` always assigns one.
- `test/lanttern/assessments_test.exs` — `:104-230` (create + name-required),
  `:455-456`, `:1413-1435` (~12 assertions on `curriculum_item.id` /
  `.curriculum_component.id`), `:1468-1491`.
- ⚠️ `priv/repo/migrations/20260616120735_require_assessment_point_name.exs:8-14`
  — the name backfill joins `curriculum_items` to derive names. Fine for
  existing data, but it's the last point that assumes every AP has a curriculum
  item.

---

## Decisions that drive everything else

1. **Join-table shape (B):** new `assessment_points_curriculum_items` — position?
   audit-logged? Everything in §2/§6 keys off this.
2. **What the composition "Curriculum" cell shows (B):** the embedded
   `student_grades_report_entry` stores singular denormalized strings, and
   historical records exist. Concatenate / first / multi-row / drop the column?
3. **Rubric ↔ AP matching (B):** §4 hinges entirely on a single shared
   `curriculum_item_id`. Least obvious blast radius, probably the hardest call.
4. **INNER → LEFT join sweep (A):** mechanical but ~13 query sites; the
   `select:`-rebuild ones in `assessments.ex` need care.
