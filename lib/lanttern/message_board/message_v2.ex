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
          message_classes_v2: [MessageClass.t()] | Ecto.Association.NotLoaded.t(),
          classes: [Class.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "messages" do
    field :name, :string
    field :description, :string
    field :send_to, Ecto.Enum, values: [school: "school", classes: "classes"]
    field :send_to_form, :string, virtual: true
    field :archived_at, :utc_datetime
    field :subtitle, :string
    field :color, :string
    field :cover, :string
    field :position, :integer, default: 0
    field :classes_ids, {:array, :id}, virtual: true
    belongs_to :school, School
    belongs_to :section, Section
    has_many :message_classes_v2, MessageClass, on_replace: :delete, foreign_key: :message_id
    has_many :classes, through: [:message_classes_v2, :class]
    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    attrs = convert_send_to_form_to_send_to(attrs)

    changeset =
      message
      |> cast(attrs, [
        :name,
        :description,
        :school_id,
        :send_to,
        :send_to_form,
        :section_id,
        :subtitle,
        :color,
        :cover,
        :position
      ])
      |> set_send_to_form_from_send_to()
      |> validate_required([:name, :description, :school_id, :section_id])
      |> validate_send_to_when_present()

    case get_field(changeset, :send_to) do
      :classes -> changeset |> cast(attrs, [:classes_ids]) |> cast_and_validate_classes()
      _ -> changeset
    end
  end

  @doc false
  def save_changeset(message, attrs) do
    message
    |> changeset(attrs)
    |> validate_required([:send_to])
  end

  defp convert_send_to_form_to_send_to(attrs) do
    case attrs["send_to_form"] do
      value when value in ["school", "classes"] -> Map.put(attrs, "send_to", value)
      _ -> attrs
    end
  end

  defp set_send_to_form_from_send_to(changeset) do
    send_to = get_field(changeset, :send_to)
    send_to_string = if send_to in [:school, :classes], do: Atom.to_string(send_to), else: send_to

    if send_to_string in ["school", "classes"] do
      put_change(changeset, :send_to_form, send_to_string)
    else
      changeset
    end
  end

  defp validate_send_to_when_present(changeset) do
    case get_field(changeset, :send_to) do
      nil ->
        changeset

      _send_to ->
        changeset
        |> validate_required([:send_to])
        |> validate_inclusion(:send_to, [:school, :classes],
          message: gettext("Send to must be 'school' or 'classes'")
        )
    end
  end

  defp cast_and_validate_classes(changeset) do
    changeset = cast_classes(changeset, get_change(changeset, :classes_ids))

    case get_field(changeset, :message_classes_v2) do
      [] -> add_error(changeset, :classes_ids, gettext("At least 1 class is required"))
      _ -> changeset
    end
  end

  defp cast_classes(changeset, classes_ids) when is_list(classes_ids) do
    school_id = get_field(changeset, :school_id)
    message_classes_params = Enum.map(classes_ids, &%{class_id: &1, school_id: school_id})

    changeset
    |> put_change(:message_classes_v2, message_classes_params)
    |> cast_assoc(:message_classes_v2)
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
