defmodule Lanttern.BNCC.Habilidade do
  use Ecto.Schema

  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Taxonomy.Subject
  alias Lanttern.Taxonomy.Year

  @primary_key {:id, :id, autogenerate: true}

  embedded_schema do
    field :code, :string
    field :name, :string

    belongs_to :objeto_de_conhecimento, CurriculumItem
    belongs_to :unidade_tematica, CurriculumItem

    embeds_many :subjects, Subject
    embeds_many :years, Year
  end
end
