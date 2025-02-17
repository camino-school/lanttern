# Script for populating the database. You can run it locally as:
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

Taxonomy.seed_base_taxonomy()

g10 = Repo.get_by!(Taxonomy.Year, code: "g10")

engl = Repo.get_by!(Taxonomy.Subject, code: "engl")
port = Repo.get_by!(Taxonomy.Subject, code: "port")
espa = Repo.get_by!(Taxonomy.Subject, code: "espa")
hsci = Repo.get_by!(Taxonomy.Subject, code: "hsci")
scie = Repo.get_by!(Taxonomy.Subject, code: "scie")
tech = Repo.get_by!(Taxonomy.Subject, code: "tech")
engi = Repo.get_by!(Taxonomy.Subject, code: "engi")
math = Repo.get_by!(Taxonomy.Subject, code: "math")
vart = Repo.get_by!(Taxonomy.Subject, code: "vart")
dram = Repo.get_by!(Taxonomy.Subject, code: "dram")
musi = Repo.get_by!(Taxonomy.Subject, code: "musi")
move = Repo.get_by!(Taxonomy.Subject, code: "move")

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

staff_member = Repo.insert!(%Schools.StaffMember{school_id: school.id, name: "The Teacher"})
_staff_member_1 = Repo.insert!(%Schools.StaffMember{school_id: school.id, name: "Teacher 1"})
_staff_member_2 = Repo.insert!(%Schools.StaffMember{school_id: school.id, name: "Teacher 2"})

cycle =
  Repo.insert!(%Schools.Cycle{
    school_id: school.id,
    name: "2024",
    start_at: ~D[2024-01-01],
    end_at: ~D[2024-12-31]
  })

# use changeset to `put_assoc` students
_class_1 =
  Schools.Class.changeset(%Schools.Class{}, %{
    school_id: school.id,
    cycle_id: cycle.id,
    name: "Grade 1",
    students_ids: [std_1.id, std_2.id, std_3.id, std_4.id, std_5.id]
  })
  |> Repo.insert!()

_class_2 =
  Schools.Class.changeset(%Schools.Class{}, %{
    school_id: school.id,
    cycle_id: cycle.id,
    name: "Grade 2",
    students_ids: [std_6.id, std_7.id, std_8.id, std_9.id, std_10.id]
  })
  |> Repo.insert!()

# ------------------------------
# identity
# ------------------------------

# use changeset to hash password
staff_member_admin_user =
  Identity.User.registration_changeset(%Identity.User{}, %{
    email: System.get_env("ROOT_ADMIN_EMAIL"),
    password: "asdfasdfasdf"
  })
  |> Ecto.Changeset.put_change(:is_root_admin, true)
  |> Repo.insert!()

# then create a staff member profile for the created user
Repo.insert!(%Identity.Profile{
  user_id: staff_member_admin_user.id,
  staff_member_id: staff_member.id,
  type: "staff"
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
  assessment_point_id: ap_1.id,
  scale_id: camino_levels_scale.id,
  scale_type: camino_levels_scale.type
})

Repo.insert!(%Assessments.AssessmentPointEntry{
  student_id: std_2.id,
  assessment_point_id: ap_1.id,
  scale_id: camino_levels_scale.id,
  scale_type: camino_levels_scale.type
})

Repo.insert!(%Assessments.AssessmentPointEntry{
  student_id: std_3.id,
  assessment_point_id: ap_1.id,
  scale_id: camino_levels_scale.id,
  scale_type: camino_levels_scale.type
})

Repo.insert!(%Assessments.AssessmentPointEntry{
  student_id: std_4.id,
  assessment_point_id: ap_1.id,
  scale_id: camino_levels_scale.id,
  scale_type: camino_levels_scale.type
})
