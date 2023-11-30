defmodule LantternWeb.Admin.ProfileViewLive.FormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Personalization
  import LantternWeb.IdentityHelpers
  import LantternWeb.SchoolsHelpers
  import LantternWeb.TaxonomyHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          Use this form to manage profile_view records in your database.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="profile_view-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:profile_id]}
          type="select"
          label="Profile"
          prompt="Select Profile"
          options={@profile_options}
        />
        <.input field={@form[:name]} type="text" label="Name" />
        <.input
          field={@form[:subjects_ids]}
          type="select"
          label="Subject"
          options={@subject_options}
          prompt="Select subjects"
          multiple
        />
        <.input
          field={@form[:classes_ids]}
          type="select"
          label="Classes"
          options={@class_options}
          prompt="Select classes"
          multiple
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Profile view</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{profile_view: profile_view} = assigns, socket) do
    subjects_ids =
      case profile_view.subjects do
        subjects when is_list(subjects) -> subjects |> Enum.map(& &1.id)
        _ -> []
      end

    classes_ids =
      case profile_view.classes do
        classes when is_list(classes) -> classes |> Enum.map(& &1.id)
        _ -> []
      end

    changeset =
      profile_view
      |> Personalization.change_profile_view()
      |> Ecto.Changeset.cast(%{subjects_ids: subjects_ids, classes_ids: classes_ids}, [
        :subjects_ids,
        :classes_ids
      ])

    profile_options = generate_profile_options()
    subject_options = generate_subject_options()
    class_options = generate_class_options()

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign(:profile_options, profile_options)
     |> assign(:subject_options, subject_options)
     |> assign(:class_options, class_options)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"profile_view" => profile_view_params},
        socket
      ) do
    changeset =
      socket.assigns.profile_view
      |> Personalization.change_profile_view(profile_view_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event(
        "save",
        %{"profile_view" => profile_view_params},
        socket
      ) do
    save_profile_view(
      socket,
      socket.assigns.action,
      profile_view_params
    )
  end

  defp save_profile_view(socket, :edit, profile_view_params) do
    case Personalization.update_profile_view(
           socket.assigns.profile_view,
           profile_view_params
         ) do
      {:ok, profile_view} ->
        notify_parent({:saved, profile_view})

        {:noreply,
         socket
         |> put_flash(:info, "Profile view updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_profile_view(socket, :new, profile_view_params) do
    case Personalization.create_profile_view(profile_view_params) do
      {:ok, profile_view} ->
        notify_parent({:saved, profile_view})

        {:noreply,
         socket
         |> put_flash(:info, "Profile view created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
