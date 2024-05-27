defmodule Lanttern.Attachments.Attachment do
  @moduledoc """
  The `Attachment` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  import LantternWeb.Gettext

  alias Lanttern.Identity.Profile
  alias Lanttern.Notes.Note
  alias Lanttern.Notes.NoteAttachment

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t(),
          link: String.t(),
          is_external: boolean(),
          owner: Profile.t(),
          owner_id: pos_integer(),
          note: Note.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "attachments" do
    field :name, :string
    field :link, :string
    field :description, :string
    field :is_external, :boolean, default: false

    belongs_to :owner, Profile

    has_one :note_attachment, NoteAttachment
    has_one :note, through: [:note_attachment, :note]

    timestamps()
  end

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:name, :description, :link, :is_external, :owner_id])
    |> validate_required([:name, :link, :owner_id])
    |> validate_change(:link, fn :link, link ->
      case URI.new(link) do
        {:error, _} ->
          [link: gettext("Invalid link format")]

        {:ok, %URI{scheme: scheme}} when scheme not in ["https", "http"] ->
          [link: gettext("Links should start with \"https://\" or \"http://\"")]

        {:ok, _} ->
          []
      end
    end)
  end
end
