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
alias Lanttern.Curricula
alias Lanttern.Grading

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

Repo.insert!(%Lanttern.Grading.OrdinalValue{
  name: "E",
  normalized_value: 0.0,
  scale_id: letter_grade_scale.id
})

Repo.insert!(%Lanttern.Grading.OrdinalValue{
  name: "D",
  normalized_value: 0.25,
  scale_id: letter_grade_scale.id
})

Repo.insert!(%Lanttern.Grading.OrdinalValue{
  name: "C",
  normalized_value: 0.5,
  scale_id: letter_grade_scale.id
})

Repo.insert!(%Lanttern.Grading.OrdinalValue{
  name: "B",
  normalized_value: 0.75,
  scale_id: letter_grade_scale.id
})

Repo.insert!(%Lanttern.Grading.OrdinalValue{
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

Repo.insert!(%Lanttern.Grading.OrdinalValue{
  name: "Lack of evidence",
  normalized_value: 0.0,
  scale_id: camino_levels_scale.id
})

Repo.insert!(%Lanttern.Grading.OrdinalValue{
  name: "Emerging",
  normalized_value: 0.4,
  scale_id: camino_levels_scale.id
})

Repo.insert!(%Lanttern.Grading.OrdinalValue{
  name: "Progressing",
  normalized_value: 0.6,
  scale_id: camino_levels_scale.id
})

Repo.insert!(%Lanttern.Grading.OrdinalValue{
  name: "Achieving",
  normalized_value: 0.85,
  scale_id: camino_levels_scale.id
})

Repo.insert!(%Lanttern.Grading.OrdinalValue{
  name: "Exceeding",
  normalized_value: 1.0,
  scale_id: camino_levels_scale.id
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
