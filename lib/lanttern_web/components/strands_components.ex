defmodule LantternWeb.StrandsComponents do
  @moduledoc """
  Shared function components related to the `Strands` context.

  New strand-related UI lives here (the `LearningContext` context is being phased
  out — see `LantternWeb.LearningContextComponents`).
  """

  use Phoenix.Component

  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.DateTimeHelpers, only: [format_by_locale: 2]

  alias Lanttern.LearningContext.Strand

  @doc """
  Renders a lock indicator bar, shown only when the strand is locked.

  Surfaces *why* assessment/marking edits are blocked. Visible to everyone (no
  permission needed). Pass an `:action` slot (e.g. the unlock control) to render
  on the right for users with lock authority.
  """
  attr :strand, Strand,
    required: true,
    doc: "Requires the `:locked_by_staff_member` preload for the provenance text"

  attr :tz, :string, default: nil
  attr :class, :any, default: nil

  slot :action, doc: "optional right-aligned content (e.g. the unlock control)"

  def strand_lock_bar(assigns) do
    ~H"""
    <div
      :if={@strand.is_locked}
      class={["flex items-center gap-3 p-4 rounded-sm bg-ltrn-dark text-ltrn-lighter", @class]}
    >
      <.icon name="hero-lock-closed-mini" class="shrink-0" />
      <div class="flex-1 min-w-0 font-sans text-sm">
        <p class="font-bold">{gettext("This strand is locked")}</p>
        <p>{lock_provenance_text(@strand, @tz)}</p>
      </div>
      {render_slot(@action)}
    </div>
    """
  end

  @doc """
  Builds a human-readable provenance string ("Locked by X on Y") from a strand's
  lock provenance columns.

  Requires the `:locked_by_staff_member` preload. Returns `nil` when the strand
  is not locked.
  """
  @spec lock_provenance_text(Strand.t(), String.t() | nil) :: String.t() | nil
  def lock_provenance_text(strand, tz \\ nil)

  def lock_provenance_text(%Strand{is_locked: true} = strand, tz) do
    who =
      case strand.locked_by_staff_member do
        %{name: name} -> name
        _ -> gettext("unknown staff member")
      end

    case strand.locked_at do
      %DateTime{} = locked_at ->
        gettext("Locked by %{who} on %{when}", who: who, when: format_by_locale(locked_at, tz))

      _ ->
        gettext("Locked by %{who}", who: who)
    end
  end

  def lock_provenance_text(_strand, _tz), do: nil
end
