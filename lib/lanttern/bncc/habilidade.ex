defmodule Lanttern.BNCC.HabilidadeBNCCEF do
  use Ecto.Schema

  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Taxonomy.Subject
  alias Lanttern.Taxonomy.Year

  @primary_key {:id, :id, autogenerate: true}

  embedded_schema do
    field :code, :string
    field :name, :string

    belongs_to :campo_de_atuacao, CurriculumItem
    belongs_to :pratica_de_linguagem, CurriculumItem
    belongs_to :eixo, CurriculumItem
    belongs_to :unidade_tematica, CurriculumItem
    belongs_to :objeto_de_conhecimento, CurriculumItem

    embeds_many :subjects, Subject
    embeds_many :years, Year
  end
end
