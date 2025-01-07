defmodule LantternWeb.SchoolsComponents do
  @moduledoc """
  Shared function components related to `Schools` context
  """

  use Phoenix.Component

  import Phoenix.HTML, only: [raw: 1]
  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents

  alias Lanttern.Schools.School
  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  @doc """
  Renders a school branding footer.
  """

  attr :school, School, required: true
  attr :class, :any, default: nil

  def school_branding_footer(%{school: school} = assigns) do
    logo_image_url =
      case school.logo_image_url do
        nil ->
          nil

        url ->
          object_url_to_render_url(
            url,
            width: 128,
            height: 128
          )
      end

    assigns =
      assigns
      |> assign(:logo_image_url, logo_image_url)

    ~H"""
    <div
      class={["py-6 sm:py-10 bg-ltrn-dark", @class]}
      style={if @school.bg_color, do: "background-color: #{@school.bg_color}"}
    >
      <.responsive_container class="flex items-center gap-6 sm:gap-10">
        <div
          :if={@logo_image_url}
          class="shrink-0 w-32 h-32 rounded-full bg-white bg-cover bg-center shadow-lg"
          style={"background-image: url('#{@logo_image_url}')"}
        >
          <span class="sr-only"><%= gettext("School logo") %></span>
        </div>
        <div
          class="flex-1 text-white"
          style={if @school.text_color, do: "color: #{@school.text_color}"}
        >
          <p>
            <%= gettext(
              "Students information and learning data by %{school_name}.",
              school_name: "<strong>#{@school.name}</strong>"
            )
            |> raw() %>
          </p>
          <p class="mt-4">
            <%= gettext(
              "Powered by %{lanttern}.",
              lanttern: "<strong>Lanttern</strong>"
            )
            |> raw() %>
          </p>
        </div>
      </.responsive_container>
    </div>
    """
  end
end
