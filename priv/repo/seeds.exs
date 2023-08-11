# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Lanttern.Repo.insert!(%Lanttern.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Lanttern.Repo

alias Lanttern.Assessments
alias Lanttern.Curricula
alias Lanttern.Identity
alias Lanttern.Grading
alias Lanttern.Schools

# ------------------------------
# school
# ------------------------------

std_1 = Repo.insert!(%Schools.Student{name: "Bia"})
std_2 = Repo.insert!(%Schools.Student{name: "Alberto"})
std_3 = Repo.insert!(%Schools.Student{name: "Zeca"})
std_4 = Repo.insert!(%Schools.Student{name: "Juju"})

# use changeset to `put_assoc` students
class_1 =
  Schools.Class.changeset(%Schools.Class{}, %{
    name: "Grade X",
    students_ids: [std_1.id, std_2.id, std_3.id]
  })
  |> Repo.insert!()

# ------------------------------
# identity
# ------------------------------

# use changeset to hash password
Identity.User.registration_changeset(%Identity.User{}, %{
  email: System.get_env("ROOT_ADMIN_EMAIL"),
  password: "asdfasdfasdf"
})
|> Ecto.Changeset.put_change(:is_root_admin, true)
|> Repo.insert!()

# ------------------------------
# curriculum
# ------------------------------

en_lo_1 = Repo.insert!(%Curricula.Item{name: "English LO 1"})

# ------------------------------
# scales
# ------------------------------

# A—E
letter_grade_scale =
  Repo.insert!(%Grading.Scale{
    name: "Letter Grade A—E",
    type: "ordinal",
    breakpoints: [0.2, 0.4, 0.6, 0.8]
  })

Repo.insert!(%Grading.OrdinalValue{
  name: "E",
  normalized_value: 0.0,
  scale_id: letter_grade_scale.id
})

Repo.insert!(%Grading.OrdinalValue{
  name: "D",
  normalized_value: 0.25,
  scale_id: letter_grade_scale.id
})

Repo.insert!(%Grading.OrdinalValue{
  name: "C",
  normalized_value: 0.5,
  scale_id: letter_grade_scale.id
})

Repo.insert!(%Grading.OrdinalValue{
  name: "B",
  normalized_value: 0.75,
  scale_id: letter_grade_scale.id
})

Repo.insert!(%Grading.OrdinalValue{
  name: "A",
  normalized_value: 1.0,
  scale_id: letter_grade_scale.id
})

# Camino Levels
camino_levels_scale =
  Repo.insert!(%Grading.Scale{
    name: "Camino Levels",
    type: "ordinal",
    breakpoints: [0.2, 0.5, 0.7, 0.9]
  })

Repo.insert!(%Grading.OrdinalValue{
  name: "Lack of evidence",
  normalized_value: 0.0,
  scale_id: camino_levels_scale.id
})

Repo.insert!(%Grading.OrdinalValue{
  name: "Emerging",
  normalized_value: 0.4,
  scale_id: camino_levels_scale.id
})

Repo.insert!(%Grading.OrdinalValue{
  name: "Progressing",
  normalized_value: 0.6,
  scale_id: camino_levels_scale.id
})

Repo.insert!(%Grading.OrdinalValue{
  name: "Achieving",
  normalized_value: 0.85,
  scale_id: camino_levels_scale.id
})

Repo.insert!(%Grading.OrdinalValue{
  name: "Exceeding",
  normalized_value: 1.0,
  scale_id: camino_levels_scale.id
})

# ------------------------------
# assessment points
# ------------------------------

ap_1 =
  Repo.insert!(%Assessments.AssessmentPoint{
    name: "English reading",
    description: "Eius recusandae dolores voluptatem pariatur mollitia voluptatem vel porro.",
    date: DateTime.utc_now(:second),
    curriculum_item_id: en_lo_1.id,
    scale_id: camino_levels_scale.id
  })

Repo.insert!(%Assessments.AssessmentPointEntry{
  student_id: std_1.id,
  assessment_point_id: ap_1.id
})

Repo.insert!(%Assessments.AssessmentPointEntry{
  student_id: std_2.id,
  assessment_point_id: ap_1.id
})

Repo.insert!(%Assessments.AssessmentPointEntry{
  student_id: std_3.id,
  assessment_point_id: ap_1.id
})

Repo.insert!(%Assessments.AssessmentPointEntry{
  student_id: std_4.id,
  assessment_point_id: ap_1.id
})

# ------------------------------
# grade compositions
# ------------------------------

english_grade_composition =
  Repo.insert!(%Grading.Composition{
    name: "English G5 2023Q3",
    final_grade_scale_id: letter_grade_scale.id
  })

english_grade_composition_component =
  Repo.insert!(%Grading.CompositionComponent{
    name: "Learning objectives",
    weight: 1.0,
    composition_id: english_grade_composition.id
  })

Repo.insert!(%Grading.CompositionComponentItem{
  component_id: english_grade_composition_component.id,
  curriculum_item_id: en_lo_1.id,
  weight: 1.0
})
