defmodule Lanttern.MessageBoard.Message do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: Lanttern.Gettext

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

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:name, :description, :send_to, :school_id, :archived_at])
    |> validate_required([:name, :description, :send_to, :school_id])
    |> check_constraint(
      :send_to,
      name: :valid_send_to,
      message: gettext("Send to must be 'school' or 'classes'")
    )
  end
end
