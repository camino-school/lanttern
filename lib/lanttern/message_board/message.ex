defmodule Lanttern.MessageBoard.Message do
  @moduledoc """
  The `Message` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.MessageBoard.MessageClass
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t(),
          send_to: String.t(),
          archived_at: DateTime.t() | nil,
          school_id: pos_integer() | nil,
          school: School.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "board_messages" do
    field :name, :string
    field :description, :string
    field :send_to, :string
    field :archived_at, :utc_datetime

    field :classes_ids, {:array, :id}, virtual: true

    belongs_to :school, School

    has_many :message_classes, MessageClass, on_replace: :delete
    has_many :classes, through: [:message_classes, :class]

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    changeset =
      message
      |> cast(attrs, [:name, :description, :school_id, :send_to])
      |> validate_required([:name, :description, :school_id, :send_to])
      |> check_constraint(
        :send_to,
        name: :valid_send_to,
        message: gettext("Send to must be 'school' or 'classes'")
      )

    case get_field(changeset, :send_to) do
      "classes" ->
        changeset
        |> cast(attrs, [:classes_ids])
        |> cast_and_validate_classes()

      _ ->
        changeset
    end
  end

  defp cast_and_validate_classes(changeset) do
    changeset =
      cast_classes(
        changeset,
        get_change(changeset, :classes_ids)
      )

    case get_field(changeset, :message_classes) do
      [] ->
        add_error(changeset, :classes_ids, gettext("At least 1 class is required"))

      _ ->
        changeset
    end
  end

  defp cast_classes(changeset, classes_ids) when is_list(classes_ids) do
    school_id = get_field(changeset, :school_id)

    message_classes_params =
      Enum.map(classes_ids, &%{class_id: &1, school_id: school_id})

    changeset
    |> put_change(:message_classes, message_classes_params)
    |> cast_assoc(:message_classes)
  end

  defp cast_classes(changeset, _), do: changeset

  @doc false
  def archive_changeset(message) do
    message
    |> cast(%{archived_at: DateTime.utc_now()}, [:archived_at])
  end

  @doc false
  def unarchive_changeset(message) do
    message
    |> cast(%{archived_at: nil}, [:archived_at])
  end
end
