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

std_1 = Repo.insert!(%Schools.Student{name: "Std 1"})
std_2 = Repo.insert!(%Schools.Student{name: "Std 2"})
std_3 = Repo.insert!(%Schools.Student{name: "Std 3"})
std_4 = Repo.insert!(%Schools.Student{name: "Std 4"})
std_5 = Repo.insert!(%Schools.Student{name: "Std 5"})
std_6 = Repo.insert!(%Schools.Student{name: "Std 6"})
std_7 = Repo.insert!(%Schools.Student{name: "Std 7"})
std_8 = Repo.insert!(%Schools.Student{name: "Std 8"})
std_9 = Repo.insert!(%Schools.Student{name: "Std 9"})
std_10 = Repo.insert!(%Schools.Student{name: "Std 10"})

# use changeset to `put_assoc` students
class_1 =
  Schools.Class.changeset(%Schools.Class{}, %{
    name: "Grade 1",
    students_ids: [std_1.id, std_2.id, std_3.id, std_4.id, std_5.id]
  })
  |> Repo.insert!()

class_2 =
  Schools.Class.changeset(%Schools.Class{}, %{
    name: "Grade 2",
    students_ids: [std_6.id, std_7.id, std_8.id, std_9.id, std_10.id]
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
pt_lo_1 = Repo.insert!(%Curricula.Item{name: "Portuguese LO 1"})
es_lo_1 = Repo.insert!(%Curricula.Item{name: "Spanish LO 1"})
hs_lo_1 = Repo.insert!(%Curricula.Item{name: "Human Sciences LO 1"})
sci_lo_1 = Repo.insert!(%Curricula.Item{name: "Science LO 1"})
tech_lo_1 = Repo.insert!(%Curricula.Item{name: "Technology LO 1"})
eng_lo_1 = Repo.insert!(%Curricula.Item{name: "Engineering LO 1"})
math_lo_1 = Repo.insert!(%Curricula.Item{name: "Math LO 1"})
va_lo_1 = Repo.insert!(%Curricula.Item{name: "Visual Arts LO 1"})
dra_lo_1 = Repo.insert!(%Curricula.Item{name: "Drama LO 1"})
mus_lo_1 = Repo.insert!(%Curricula.Item{name: "Music LO 1"})
mov_lo_1 = Repo.insert!(%Curricula.Item{name: "Movement LO 1"})

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

# 0 to 10
Repo.insert!(%Grading.Scale{
  name: "0 to 10",
  type: "numeric"
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
