defmodule Lanttern.Curricula.CurriculumComponent do
  @moduledoc """
  The `CurriculumComponent` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  schema "curriculum_components" do
    field :code, :string
    field :name, :string
    field :description, :string
    field :position, :integer, default: 0
    field :bg_color, :string
    field :text_color, :string

    belongs_to :curriculum, Lanttern.Curricula.Curriculum

    timestamps()
  end

  @doc false
  def changeset(curriculum_component, attrs) do
    curriculum_component
    |> cast(attrs, [:code, :name, :description, :position, :bg_color, :text_color, :curriculum_id])
    |> validate_required([:name, :curriculum_id])
    |> check_constraint(:bg_color,
      name: :bg_color_should_be_hex,
      message: gettext("Background color format not accepted. Use hex color.")
    )
    |> check_constraint(:text_color,
      name: :text_color_should_be_hex,
      message: gettext("Text color format not accepted. Use hex color.")
    )
  end
end
