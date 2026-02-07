defmodule Lanttern.Lessons.Lesson do
  @moduledoc """
  The `Lesson` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Repo

  import Lanttern.SchemaHelpers, only: [put_subjects: 1]

  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Lessons.Tag
  alias Lanttern.Taxonomy.Subject

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t() | nil,
          teacher_notes: String.t() | nil,
          differentiation_notes: String.t() | nil,
          is_published: boolean(),
          position: non_neg_integer(),
          strand: Strand.t() | Ecto.Association.NotLoaded.t(),
          strand_id: pos_integer(),
          moment: Moment.t() | Ecto.Association.NotLoaded.t(),
          moment_id: pos_integer() | nil,
          subjects: [Subject.t()] | Ecto.Association.NotLoaded.t(),
          tags: [Tag.t() | Ecto.Association.NotLoaded.t()],
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "lessons" do
    field :name, :string
    field :description, :string
    field :teacher_notes, :string
    field :differentiation_notes, :string
    field :is_published, :boolean, default: false
    field :position, :integer, default: 0

    field :subjects_ids, {:array, :id}, virtual: true
    field :tags_ids, {:array, :id}, virtual: true

    belongs_to :strand, Strand
    belongs_to :moment, Moment

    many_to_many :subjects, Subject, join_through: "lessons_subjects", on_replace: :delete
    many_to_many :tags, Tag, join_through: "lessons_tags", on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(lesson, attrs) do
    lesson
    |> cast(attrs, [
      :name,
      :description,
      :teacher_notes,
      :differentiation_notes,
      :is_published,
      :position,
      :strand_id,
      :moment_id,
      :subjects_ids,
      :tags_ids
    ])
    |> validate_required([:name, :position, :strand_id])
    |> validate_published_lesson()
    |> put_subjects()
    |> put_tags()
  end

  defp validate_published_lesson(changeset) do
    is_published = get_field(changeset, :is_published)
    description = get_field(changeset, :description)

    if is_published && (is_nil(description) || String.trim(description) == "") do
      add_error(
        changeset,
        :description,
        gettext("Description can't be blank when lesson is published")
      )
    else
      changeset
    end
  end

  def put_tags(changeset) do
    put_tags(
      changeset,
      get_change(changeset, :tags_ids)
    )
  end

  defp put_tags(changeset, nil), do: changeset

  defp put_tags(changeset, tags_ids) do
    tags =
      from(t in Tag, where: t.id in ^tags_ids)
      |> Repo.all()

    changeset
    |> put_assoc(:tags, tags)
  end
end
