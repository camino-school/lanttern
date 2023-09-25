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
alias Lanttern.Taxonomy

# ------------------------------
# taxonomy
# ------------------------------

_k1 = Repo.insert!(%Taxonomy.Year{code: "k1", name: "Kindergarten 1"})
_k2 = Repo.insert!(%Taxonomy.Year{code: "k2", name: "Kindergarten 2"})
_k3 = Repo.insert!(%Taxonomy.Year{code: "k3", name: "Kindergarten 3"})
_k4 = Repo.insert!(%Taxonomy.Year{code: "k4", name: "Kindergarten 4"})
_k5 = Repo.insert!(%Taxonomy.Year{code: "k5", name: "Kindergarten 5"})
_g1 = Repo.insert!(%Taxonomy.Year{code: "g1", name: "Grade 1"})
_g2 = Repo.insert!(%Taxonomy.Year{code: "g2", name: "Grade 2"})
_g3 = Repo.insert!(%Taxonomy.Year{code: "g3", name: "Grade 3"})
_g4 = Repo.insert!(%Taxonomy.Year{code: "g4", name: "Grade 4"})
_g5 = Repo.insert!(%Taxonomy.Year{code: "g5", name: "Grade 5"})
_g6 = Repo.insert!(%Taxonomy.Year{code: "g6", name: "Grade 6"})
_g7 = Repo.insert!(%Taxonomy.Year{code: "g7", name: "Grade 7"})
_g8 = Repo.insert!(%Taxonomy.Year{code: "g8", name: "Grade 8"})
_g9 = Repo.insert!(%Taxonomy.Year{code: "g9", name: "Grade 9"})
g10 = Repo.insert!(%Taxonomy.Year{code: "g10", name: "Grade 10"})
_g11 = Repo.insert!(%Taxonomy.Year{code: "g11", name: "Grade 11"})
_g12 = Repo.insert!(%Taxonomy.Year{code: "g12", name: "Grade 12"})

engl = Repo.insert!(%Taxonomy.Subject{code: "engl", name: "English"})
port = Repo.insert!(%Taxonomy.Subject{code: "port", name: "Portuguese"})
espa = Repo.insert!(%Taxonomy.Subject{code: "espa", name: "Spanish"})
hsci = Repo.insert!(%Taxonomy.Subject{code: "hsci", name: "Human Sciences"})
_geog = Repo.insert!(%Taxonomy.Subject{code: "geog", name: "Geography"})
_hist = Repo.insert!(%Taxonomy.Subject{code: "hist", name: "History"})
scie = Repo.insert!(%Taxonomy.Subject{code: "scie", name: "Science"})
tech = Repo.insert!(%Taxonomy.Subject{code: "tech", name: "Technology"})
engi = Repo.insert!(%Taxonomy.Subject{code: "engi", name: "Engineering"})
math = Repo.insert!(%Taxonomy.Subject{code: "math", name: "Math"})
_arts = Repo.insert!(%Taxonomy.Subject{code: "arts", name: "Arts"})
vart = Repo.insert!(%Taxonomy.Subject{code: "vart", name: "Visual Arts"})
dram = Repo.insert!(%Taxonomy.Subject{code: "dram", name: "Drama"})
musi = Repo.insert!(%Taxonomy.Subject{code: "musi", name: "Music"})
move = Repo.insert!(%Taxonomy.Subject{code: "move", name: "Movement"})
_reli = Repo.insert!(%Taxonomy.Subject{code: "reli", name: "Religion"})

# ------------------------------
# school
# ------------------------------

school = Repo.insert!(%Schools.School{name: "The School"})

std_1 = Repo.insert!(%Schools.Student{school_id: school.id, name: "Std 1"})
std_2 = Repo.insert!(%Schools.Student{school_id: school.id, name: "Std 2"})
std_3 = Repo.insert!(%Schools.Student{school_id: school.id, name: "Std 3"})
std_4 = Repo.insert!(%Schools.Student{school_id: school.id, name: "Std 4"})
std_5 = Repo.insert!(%Schools.Student{school_id: school.id, name: "Std 5"})
std_6 = Repo.insert!(%Schools.Student{school_id: school.id, name: "Std 6"})
std_7 = Repo.insert!(%Schools.Student{school_id: school.id, name: "Std 7"})
std_8 = Repo.insert!(%Schools.Student{school_id: school.id, name: "Std 8"})
std_9 = Repo.insert!(%Schools.Student{school_id: school.id, name: "Std 9"})
std_10 = Repo.insert!(%Schools.Student{school_id: school.id, name: "Std 10"})

teacher = Repo.insert!(%Schools.Teacher{school_id: school.id, name: "The Teacher"})
_teacher_1 = Repo.insert!(%Schools.Teacher{school_id: school.id, name: "Teacher 1"})
_teacher_2 = Repo.insert!(%Schools.Teacher{school_id: school.id, name: "Teacher 2"})

# use changeset to `put_assoc` students
_class_1 =
  Schools.Class.changeset(%Schools.Class{}, %{
    school_id: school.id,
    name: "Grade 1",
    students_ids: [std_1.id, std_2.id, std_3.id, std_4.id, std_5.id]
  })
  |> Repo.insert!()

_class_2 =
  Schools.Class.changeset(%Schools.Class{}, %{
    school_id: school.id,
    name: "Grade 2",
    students_ids: [std_6.id, std_7.id, std_8.id, std_9.id, std_10.id]
  })
  |> Repo.insert!()

# ------------------------------
# identity
# ------------------------------

# use changeset to hash password
teacher_admin_user =
  Identity.User.registration_changeset(%Identity.User{}, %{
    email: System.get_env("ROOT_ADMIN_EMAIL"),
    password: "asdfasdfasdf"
  })
  |> Ecto.Changeset.put_change(:is_root_admin, true)
  |> Repo.insert!()

# then create a teacher profile for the created user
Repo.insert!(%Identity.Profile{
  user_id: teacher_admin_user.id,
  teacher_id: teacher.id,
  type: "teacher"
})

# use changeset to hash password
student_user =
  Identity.User.registration_changeset(%Identity.User{}, %{
    email: "student@email.com",
    password: "asdfasdfasdf"
  })
  |> Repo.insert!()

# then create a student profile for the created user
Repo.insert!(%Identity.Profile{user_id: student_user.id, student_id: std_1.id, type: "student"})

# ------------------------------
# curriculum
# ------------------------------

curriculum = Repo.insert!(%Curricula.Curriculum{name: "The Curriculum"})

curriculum_component =
  Repo.insert!(%Curricula.CurriculumComponent{
    name: "Learning Objective",
    code: "LO",
    curriculum_id: curriculum.id
  })

# use changeset to `put_assoc` subjects and years

en_lo =
  Curricula.CurriculumItem.changeset(%Curricula.CurriculumItem{}, %{
    name: "English LO 1",
    curriculum_component_id: curriculum_component.id,
    subjects_ids: [engl.id],
    years_ids: [g10.id]
  })
  |> Repo.insert!()

_pt_lo =
  Curricula.CurriculumItem.changeset(%Curricula.CurriculumItem{}, %{
    name: "Portuguese LO 1",
    curriculum_component_id: curriculum_component.id,
    subjects_ids: [port.id],
    years_ids: [g10.id]
  })
  |> Repo.insert!()

_es_lo =
  Curricula.CurriculumItem.changeset(%Curricula.CurriculumItem{}, %{
    name: "Spanish LO 1",
    curriculum_component_id: curriculum_component.id,
    subjects_ids: [espa.id],
    years_ids: [g10.id]
  })
  |> Repo.insert!()

_hs_lo =
  Curricula.CurriculumItem.changeset(%Curricula.CurriculumItem{}, %{
    name: "Human Sciences LO 1",
    curriculum_component_id: curriculum_component.id,
    subjects_ids: [hsci.id],
    years_ids: [g10.id]
  })
  |> Repo.insert!()

_sci_lo =
  Curricula.CurriculumItem.changeset(%Curricula.CurriculumItem{}, %{
    name: "Science LO 1",
    curriculum_component_id: curriculum_component.id,
    subjects_ids: [scie.id],
    years_ids: [g10.id]
  })
  |> Repo.insert!()

_tech_lo =
  Curricula.CurriculumItem.changeset(%Curricula.CurriculumItem{}, %{
    name: "Technology LO 1",
    curriculum_component_id: curriculum_component.id,
    subjects_ids: [tech.id],
    years_ids: [g10.id]
  })
  |> Repo.insert!()

_eng_lo =
  Curricula.CurriculumItem.changeset(%Curricula.CurriculumItem{}, %{
    name: "Engineering LO 1",
    curriculum_component_id: curriculum_component.id,
    subjects_ids: [engi.id],
    years_ids: [g10.id]
  })
  |> Repo.insert!()

_math_lo =
  Curricula.CurriculumItem.changeset(%Curricula.CurriculumItem{}, %{
    name: "Math LO 1",
    curriculum_component_id: curriculum_component.id,
    subjects_ids: [math.id],
    years_ids: [g10.id]
  })
  |> Repo.insert!()

_var_lo =
  Curricula.CurriculumItem.changeset(%Curricula.CurriculumItem{}, %{
    name: "Visual Arts LO 1",
    curriculum_component_id: curriculum_component.id,
    subjects_ids: [vart.id],
    years_ids: [g10.id]
  })
  |> Repo.insert!()

_dra_lo =
  Curricula.CurriculumItem.changeset(%Curricula.CurriculumItem{}, %{
    name: "Drama LO 1",
    curriculum_component_id: curriculum_component.id,
    subjects_ids: [dram.id],
    years_ids: [g10.id]
  })
  |> Repo.insert!()

_mus_lo =
  Curricula.CurriculumItem.changeset(%Curricula.CurriculumItem{}, %{
    name: "Music LO 1",
    curriculum_component_id: curriculum_component.id,
    subjects_ids: [musi.id],
    years_ids: [g10.id]
  })
  |> Repo.insert!()

_mov_lo =
  Curricula.CurriculumItem.changeset(%Curricula.CurriculumItem{}, %{
    name: "Movement LO 1",
    curriculum_component_id: curriculum_component.id,
    subjects_ids: [move.id],
    years_ids: [g10.id]
  })
  |> Repo.insert!()

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
  scale_id: letter_grade_scale.id,
  bg_color: "#2D0808",
  text_color: "#FFFFFF"
})

Repo.insert!(%Grading.OrdinalValue{
  name: "D",
  normalized_value: 0.25,
  scale_id: letter_grade_scale.id,
  bg_color: "#F28888",
  text_color: "#F6DFDF"
})

Repo.insert!(%Grading.OrdinalValue{
  name: "C",
  normalized_value: 0.5,
  scale_id: letter_grade_scale.id,
  bg_color: "#FFF48F",
  text_color: "#756A07"
})

Repo.insert!(%Grading.OrdinalValue{
  name: "B",
  normalized_value: 0.75,
  scale_id: letter_grade_scale.id,
  bg_color: "#5CD9BB",
  text_color: "#133F34"
})

Repo.insert!(%Grading.OrdinalValue{
  name: "A",
  normalized_value: 1.0,
  scale_id: letter_grade_scale.id,
  bg_color: "#814BF4",
  text_color: "#D9C8FC"
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
  scale_id: camino_levels_scale.id,
  bg_color: "#2D0808",
  text_color: "#FFFFFF"
})

Repo.insert!(%Grading.OrdinalValue{
  name: "Emerging",
  normalized_value: 0.4,
  scale_id: camino_levels_scale.id,
  bg_color: "#F28888",
  text_color: "#F6DFDF"
})

Repo.insert!(%Grading.OrdinalValue{
  name: "Progressing",
  normalized_value: 0.6,
  scale_id: camino_levels_scale.id,
  bg_color: "#FFF48F",
  text_color: "#756A07"
})

Repo.insert!(%Grading.OrdinalValue{
  name: "Achieving",
  normalized_value: 0.85,
  scale_id: camino_levels_scale.id,
  bg_color: "#5CD9BB",
  text_color: "#133F34"
})

Repo.insert!(%Grading.OrdinalValue{
  name: "Exceeding",
  normalized_value: 1.0,
  scale_id: camino_levels_scale.id,
  bg_color: "#814BF4",
  text_color: "#D9C8FC"
})

# 0 to 10
Repo.insert!(%Grading.Scale{
  name: "0 to 10",
  type: "numeric",
  start: 0.0,
  stop: 10.0
})

# ------------------------------
# assessment points
# ------------------------------

ap_1 =
  Repo.insert!(%Assessments.AssessmentPoint{
    name: "English reading",
    description: "Eius recusandae dolores voluptatem pariatur mollitia voluptatem vel porro.",
    date: DateTime.utc_now(:second),
    curriculum_item_id: en_lo.id,
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
  curriculum_item_id: en_lo.id,
  weight: 1.0
})
