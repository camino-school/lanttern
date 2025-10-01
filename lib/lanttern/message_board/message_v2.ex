defmodule Lanttern.MessageBoard.MessageV2 do
  @moduledoc """
  The `MessageV2` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.MessageBoard.MessageClassV2, as: MessageClass
  alias Lanttern.MessageBoard.Section
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t(),
          subtitle: String.t() | nil,
          color: String.t() | nil,
          cover: String.t() | nil,
          send_to: :school | :classes,
          archived_at: DateTime.t() | nil,
          position: non_neg_integer(),
          school_id: pos_integer(),
          section_id: pos_integer(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          section: Section.t() | Ecto.Association.NotLoaded.t(),
          classes_ids: [pos_integer()] | nil,
          message_classes: [MessageClass.t()] | Ecto.Association.NotLoaded.t(),
          classes: [Class.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "messages" do
    field :name, :string
    field :description, :string
    field :send_to, Ecto.Enum, values: [:school, :classes]
    field :archived_at, :utc_datetime
    field :subtitle, :string
    field :color, :string
    field :cover, :string
    field :position, :integer, default: 0
    field :classes_ids, {:array, :id}, virtual: true
    belongs_to :school, School
    belongs_to :section, Section
    has_many :message_classes, MessageClass, on_replace: :delete, foreign_key: :message_id
    has_many :classes, through: [:message_classes, :class]
    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    changeset =
      message
      |> cast(attrs, [
        :name,
        :description,
        :school_id,
        :send_to,
        :section_id,
        :subtitle,
        :color,
        :cover,
        :position
      ])
      |> validate_required([:name, :description, :school_id, :send_to, :section_id])
      |> validate_inclusion(:send_to, [:school, :classes],
        message: gettext("Send to must be 'school' or 'classes'")
      )

    case get_field(changeset, :send_to) do
      :classes -> changeset |> cast(attrs, [:classes_ids]) |> cast_and_validate_classes()
      _ -> changeset
    end
  end

  defp cast_and_validate_classes(changeset) do
    changeset = cast_classes(changeset, get_change(changeset, :classes_ids))

    case get_field(changeset, :message_classes) do
      [] -> add_error(changeset, :classes_ids, gettext("At least 1 class is required"))
      _ -> changeset
    end
  end

  defp cast_classes(changeset, classes_ids) when is_list(classes_ids) do
    school_id = get_field(changeset, :school_id)
    message_classes_params = Enum.map(classes_ids, &%{class_id: &1, school_id: school_id})

    changeset
    |> put_change(:message_classes, message_classes_params)
    |> cast_assoc(:message_classes)
  end

  defp cast_classes(changeset, _), do: changeset

  @doc false
  def archive_changeset(message) do
    message |> cast(%{archived_at: DateTime.utc_now()}, [:archived_at])
  end

  @doc false
  def unarchive_changeset(message) do
    message |> cast(%{archived_at: nil}, [:archived_at])
  end
end
