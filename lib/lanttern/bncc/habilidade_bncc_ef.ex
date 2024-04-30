defmodule Lanttern.BNCC.HabilidadeBNCCEF do
  @moduledoc """
  The `HabilidadeBNCCEF` schema
  """

  use Ecto.Schema

  alias Lanttern.Taxonomy.Subject
  alias Lanttern.Taxonomy.Year

  @primary_key {:id, :id, autogenerate: true}

  embedded_schema do
    field :code, :string
    field :name, :string

    field :campo_de_atuacao, :string
    field :pratica_de_linguagem, :string
    field :eixo, :string
    field :unidade_tematica, :string
    field :objeto_de_conhecimento, :string

    embeds_many :subjects, Subject
    embeds_many :years, Year
  end
end
