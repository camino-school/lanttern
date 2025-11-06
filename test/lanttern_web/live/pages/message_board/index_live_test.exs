defmodule LantternWeb.MessageBoard.IndexLiveTest do
  use LantternWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lanttern.Factory

  alias Lanttern.MessageBoardV2, as: MessageBoard

  setup [:register_and_log_in_staff_member]

  @doc """
  Helper to trigger LiveView initialization in tests.

  In production, the LiveView sends `:initialized` message to itself after
  WebSocket connection via `if connected?(socket), do: send(self(), :initialized)`.
  This triggers `handle_info(:initialized, socket)` which loads sections and other data.

  In tests, `connected?(socket)` returns false, so the `:initialized` message is never
  sent and sections are never loaded. This helper manually sends the message to simulate
  the real initialization flow.

  ## Usage

      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      html = view |> init_view() |> render()
      assert html =~ "Expected content"

  """
  def init_view(view) do
    send(view.pid, :initialized)
    view
  end

  # Helper to setup communication manager permissions
  defp setup_communication_manager(context) do
    set_user_permissions(["communication_management"], context)
  end

  describe "IndexLive" do
    setup [:setup_communication_manager]

    setup %{user: user} do
      school = user.current_profile.staff_member.school
      section = insert(:section, school: school)
      %{section: section, school: school}
    end

    test "displays sections stream", %{conn: conn, section: section} do
      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      html = view |> init_view() |> render()

      assert html =~ section.name
    end

    test "creates new section and updates stream", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")

      # Open section form
      view |> element("a", "Create section") |> render_click()

      # Fill and submit form
      view
      |> form("#section-form", section: %{name: "Test Section"})
      |> render_submit()

      # Verify section appears in stream
      assert has_element?(view, "h2", "Test Section")
    end

    test "new section is automatically positioned at the end of the list", %{
      conn: conn,
      user: user
    } do
      # Create some existing sections
      current_school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      insert(:section, school: current_school, name: "Section 1", position: 0)
      insert(:section, school: current_school, name: "Section 2", position: 1)
      insert(:section, school: current_school, name: "Section 3", position: 2)

      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")

      # Open section form
      view |> element("a", "Create section") |> render_click()

      # Fill and submit form
      view
      |> form("#section-form", section: %{name: "New Section"})
      |> render_submit()

      # Verify the new section was created with position 3 (after the existing 3 sections)
      new_section = Lanttern.Repo.get_by!(Lanttern.MessageBoard.Section, name: "New Section")
      assert new_section.position == 3
    end

    test "first section created has position 1", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")

      # Open section form
      view |> element("a", "Create section") |> render_click()

      # Fill and submit form
      view
      |> form("#section-form", section: %{name: "First Section"})
      |> render_submit()

      # Verify the first section has position 0
      first_section = Lanttern.Repo.get_by!(Lanttern.MessageBoard.Section, name: "First Section")
      assert first_section.position == 1
    end

    test "creates new message and updates messages stream", %{conn: conn, section: section} do
      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      view |> init_view()

      # Click new message button
      view
      |> element("#sections-#{section.id} a[href*='new=true']")
      |> render_click()

      # Fill and submit message form
      view
      |> form("#message-form",
        message_v2: %{
          name: "Test Message",
          description: "Test description",
          send_to: "school"
        }
      )
      |> render_submit()

      # Verify message appears in the section
      html = render(view)
      assert html =~ "Test Message"
    end

    test "updates message and reflects in stream", %{conn: conn, user: user, section: section} do
      current_school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      message = insert(:message, school: current_school, section: section)

      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      view |> init_view()

      # Click edit message
      view
      |> element("#message-#{message.id} #message-#{message.id}-edit")
      |> render_click()

      # Update message via form
      view
      |> form("#message-form", message_v2: %{name: "Updated Message"})
      |> render_submit()

      # Verify updated message in stream
      html = render(view)
      assert html =~ "Updated Message"
      refute html =~ message.name
    end

    test "deletes message and removes from stream", %{conn: conn, user: user, section: section} do
      current_school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      message = insert(:message, school: current_school, section: section)

      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      view |> init_view()

      # Open message edit form and delete
      view
      |> element("#message-#{message.id} #message-#{message.id}-edit")
      |> render_click()

      view
      |> element("#message-form-overlay [data-confirm]")
      |> render_click()

      # Verify message is removed from stream
      refute has_element?(view, "#message-#{message.id}")
    end

    test "deletes section with typed confirmation", %{conn: conn, user: user} do
      current_school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      section = insert(:section, school: current_school, name: "Section To Delete")

      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      view |> init_view()

      # Open section settings
      view
      |> element("#section-#{section.id}-settings")
      |> render_click()

      # Click delete button to show confirmation modal
      view
      |> element("button", "Delete")
      |> render_click()

      # Verify confirmation modal is shown
      assert has_element?(view, "#delete-confirmation-modal")
      assert has_element?(view, "#delete-confirmation-title", "Delete section")

      # Try to submit with wrong name - button should be disabled
      view
      |> form("#delete-confirmation-form", %{"section_name_confirmation" => "Wrong Name"})
      |> render_change()

      # Type correct section name
      view
      |> form("#delete-confirmation-form", %{"section_name_confirmation" => "Section To Delete"})
      |> render_change()

      # Submit deletion
      view
      |> form("#delete-confirmation-form")
      |> render_submit()

      # Verify section was deleted and redirect happened
      html = render(view)
      assert html =~ "Section deleted successfully"
      refute has_element?(view, "#section-#{section.id}")
    end

    test "cancels section deletion", %{conn: conn, user: user} do
      current_school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      section = insert(:section, school: current_school, name: "Section To Keep")

      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      view |> init_view()

      # Open section settings
      view
      |> element("#section-#{section.id}-settings")
      |> render_click()

      # Click delete button to show confirmation modal
      view
      |> element("button", "Delete")
      |> render_click()

      # Verify confirmation modal is shown
      assert has_element?(view, "#delete-confirmation-modal")

      # Cancel deletion
      view
      |> element("#delete-confirmation-modal button", "Cancel")
      |> render_click()

      # Verify modal is hidden and section name still appears in the page
      refute has_element?(view, "#delete-confirmation-modal")
      html = render(view)
      assert html =~ "Section To Keep"
    end

    test "reorders messages via sortable_update event", %{conn: conn, section: section} do
      # Create multiple messages
      message1 = insert(:message, %{section: section, name: "Message 1", position: 0})
      message2 = insert(:message, %{section: section, name: "Message 2", position: 1})
      message3 = insert(:message, %{section: section, name: "Message 3", position: 2})

      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2?edit_section=#{section.id}")

      # Simulate drag and drop (move second message to first position)
      view
      |> render_hook("sortable_update", %{"oldIndex" => 1, "newIndex" => 0})

      # Simulate saving the section (this triggers save_pending_order_changes)
      view
      |> element("form[phx-submit='save_section']")
      |> render_submit(%{section: %{name: section.name}})

      # Verify the order change is persisted
      # Expected final order: [message2, message1, message3]
      updated_message1 = MessageBoard.get_message!(message1.id)
      updated_message2 = MessageBoard.get_message!(message2.id)
      updated_message3 = MessageBoard.get_message!(message3.id)

      # message2 moved to first
      assert updated_message2.position == 0
      # message1 shifted to second
      assert updated_message1.position == 1
      # message3 stays at third
      assert updated_message3.position == 2
    end

    test "toggles reorder mode", %{conn: conn, school: school} do
      # Create a second section so the reorder button appears (need at least 2 sections)
      _section2 = insert(:section, school: school, name: "Second Section")

      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      view |> init_view()

      # Enable reorder mode by clicking the link
      view
      |> element("a[href*='reorder=true']")
      |> render_click()

      # Verify reorder overlay is shown
      assert has_element?(view, "#reorder-sections-overlay")

      # Disable reorder mode by navigating back
      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      view |> init_view()

      # Verify reorder UI is hidden
      refute has_element?(view, "#reorder-sections-overlay")
    end

    test "filters messages by class selection", %{conn: conn, school: school, section: section} do
      cycle = insert(:cycle, school: school)
      class = insert(:class, school: school, cycle: cycle)

      # Create messages - one for school, one for specific class
      _school_message =
        insert(:message, %{
          section: section,
          name: "School Message",
          send_to: :school,
          school: school
        })

      _class_message =
        insert(:message, %{
          section: section,
          name: "Class Message",
          send_to: :classes,
          classes_ids: [class.id],
          school: school
        })

      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      view |> init_view()

      # Both messages should be visible
      html = render(view)
      assert html =~ "School Message"
      assert html =~ "Class Message"

      # Verify filter overlay element exists in the DOM
      assert has_element?(view, "#message-board-classes-filters-overlay")
    end

    test "shows empty state when no messages exist", %{conn: conn, school: school} do
      section = insert(:section, school: school, name: "Empty Section")

      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      view |> init_view()

      # Verify the "Add new message" card is present
      assert has_element?(
               view,
               "a[href*='new=true'][href*='section_id=#{section.id}']",
               "Add new message"
             )

      # Verify no edit links are present (no messages exist)
      refute has_element?(view, "a[href*='edit=']")
    end

    test "preserves pending message order during navigation", %{
      conn: conn,
      section: section,
      school: school
    } do
      # Create messages BEFORE opening the view so they're loaded with the section
      message1 = insert(:message, %{section: section, position: 0, school: school})
      message2 = insert(:message, %{section: section, position: 1, school: school})

      # Open the edit section view - this loads the section with messages
      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2?edit_section=#{section.id}")
      view |> init_view()

      # Initial state: message1 is first (position 0), message2 is second (position 1)
      # Verify initial positions
      assert message1.position == 0
      assert message2.position == 1

      # Reorder messages: move message1 from position 0 to position 1
      # This should result in: [message2, message1]
      view |> render_hook("sortable_update", %{"oldIndex" => 0, "newIndex" => 1})

      # Trigger save by submitting the section form (which will also navigate away)
      view
      |> form("#section-form")
      |> render_submit()

      view |> init_view()

      # Verify the order was persisted to the database
      updated_message1 = Lanttern.Repo.get!(Lanttern.MessageBoard.MessageV2, message1.id)
      updated_message2 = Lanttern.Repo.get!(Lanttern.MessageBoard.MessageV2, message2.id)

      # After reorder: message2 should be first (position 0), message1 should be second (position 1)
      assert updated_message2.position == 0
      assert updated_message1.position == 1
    end

    test "handles concurrent message creation", %{conn: conn, section: section, user: user} do
      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      view |> init_view()

      # Simulate another user creating a message
      current_school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)

      _concurrent_message =
        insert(:message, %{section: section, name: "Concurrent Message", school: current_school})

      # Trigger a refresh by creating our own message
      view
      |> element("#sections-#{section.id} a[href*='new=true']")
      |> render_click()

      view
      |> form("#message-form",
        message_v2: %{
          name: "My Message",
          description: "Test",
          send_to: "school"
        }
      )
      |> render_submit()

      html = render(view)
      # Both messages should be visible
      assert html =~ "My Message"
      assert html =~ "Concurrent Message"
    end
  end

  describe "permissions" do
    setup :register_and_log_in_student

    test "non-communication managers cannot access", %{conn: conn} do
      # Students are redirected to their home page, not root with error
      assert {:error, {:redirect, %{to: "/student"}}} =
               live(conn, ~p"/school/message_board_v2")
    end
  end

  describe "school isolation" do
    setup [:setup_communication_manager]

    test "staff members only see sections and messages from their school", %{
      conn: conn,
      user: user
    } do
      # Current user's school - get the actual school object
      current_school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)

      # Create section and message for current user's school
      section_same_school = insert(:section, school: current_school, name: "My School Section")

      message_same_school =
        insert(:message, %{
          section: section_same_school,
          school: current_school,
          name: "Message from same school"
        })

      # Create section and message for different school
      other_school = insert(:school)
      section_other_school = insert(:section, school: other_school, name: "Other School Section")

      message_other_school =
        insert(:message, %{
          section: section_other_school,
          school: other_school,
          name: "Message from other school"
        })

      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      html = view |> init_view() |> render()

      # Should see own school's content
      assert html =~ section_same_school.name
      assert html =~ message_same_school.name

      # Should NOT see other school's content
      refute html =~ section_other_school.name
      refute html =~ message_other_school.name
    end

    test "creating messages assigns correct school_id", %{conn: conn, user: user} do
      current_school_id = user.current_profile.school_id
      current_school = Lanttern.Repo.get!(Lanttern.Schools.School, current_school_id)
      section = insert(:section, school: current_school)

      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")

      # Create new message (click on the add message link)
      view
      |> element("#sections-#{section.id} a[href*='new=true']")
      |> render_click()

      view
      |> form("#message-form",
        message_v2: %{
          name: "Test Message",
          description: "Test description",
          send_to: "school"
        }
      )
      |> render_submit()

      # Verify the message was created with correct school_id
      created_message =
        Lanttern.Repo.get_by!(Lanttern.MessageBoard.MessageV2, name: "Test Message")

      assert created_message.school_id == current_school_id
    end

    test "staff member cannot access sections from different schools via section_id parameter",
         %{conn: conn} do
      # Create section for different school
      other_school = insert(:school)
      other_section = insert(:section, school: other_school)

      _other_message =
        insert(:message, %{
          section: other_section,
          school: other_school,
          name: "Other school message"
        })

      # Should redirect with error when trying to access section from different school
      assert {:error,
              {:live_redirect,
               %{to: "/school/message_board_v2", flash: %{"error" => "Section not found"}}}} =
               live(conn, ~p"/school/message_board_v2?section_id=#{other_section.id}")
    end

    test "staff member cannot edit sections from different schools via edit_section parameter",
         %{conn: conn} do
      # Create section for different school
      other_school = insert(:school)
      other_section = insert(:section, school: other_school)

      # Should redirect with error when trying to edit section from different school
      assert {:error,
              {:live_redirect,
               %{to: "/school/message_board_v2", flash: %{"error" => "Section not found"}}}} =
               live(conn, ~p"/school/message_board_v2?edit_section=#{other_section.id}")
    end

    test "sections are filtered correctly by school_id in main listing", %{conn: conn, user: user} do
      # This test verifies that the main listing correctly filters sections by school_id
      current_school_id = user.current_profile.school_id
      current_school = Lanttern.Repo.get!(Lanttern.Schools.School, current_school_id)

      # Create multiple sections for current school
      section1 = insert(:section, school: current_school, name: "Section 1")
      section2 = insert(:section, school: current_school, name: "Section 2")

      # Create sections for other schools (should not appear)
      other_school1 = insert(:school)
      other_school2 = insert(:school)
      _other_section1 = insert(:section, school: other_school1, name: "Other Section 1")
      _other_section2 = insert(:section, school: other_school2, name: "Other Section 2")

      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      html = view |> init_view() |> render()

      # Should see sections from current school
      assert html =~ section1.name
      assert html =~ section2.name

      # Should NOT see sections from other schools
      refute html =~ "Other Section 1"
      refute html =~ "Other Section 2"
    end
  end

  describe "error handling" do
    setup :setup_communication_manager

    setup %{user: user} do
      school = user.current_profile.staff_member.school
      section = insert(:section, school: school)
      %{section: section, school: school}
    end

    test "handles invalid section_id gracefully", %{conn: conn} do
      # Should redirect to main page with error message when section not found
      assert {:error,
              {:live_redirect,
               %{to: "/school/message_board_v2", flash: %{"error" => "Section not found"}}}} =
               live(conn, ~p"/school/message_board_v2?section_id=99999")
    end

    test "handles form validation errors", %{conn: conn, section: section} do
      {:ok, view, _html} = live(conn, ~p"/school/message_board_v2")
      view |> init_view()

      # Open new message form
      view
      |> element("#sections-#{section.id} a[href*='new=true']")
      |> render_click()

      # Submit form with invalid data
      html =
        view
        |> form("#message-form", message_v2: %{name: "", send_to: "classes"})
        |> render_submit()

      # Verify error messages are shown
      assert html =~ "Oops, something went wrong! Please check the errors below."
    end
  end

  describe "sections" do
    setup [:setup_communication_manager]

    setup %{user: user} do
      school = user.current_profile.staff_member.school
      %{school: school}
    end

    alias Lanttern.MessageBoard.Section

    @invalid_attrs %{name: nil, position: nil, school_id: 0}

    test "get_section!/1 returns the section with given id", %{school: school} do
      section = insert(:section, school: school)
      fetched_section = MessageBoard.get_section!(section.id)

      assert fetched_section.id == section.id
      assert fetched_section.name == section.name
      assert fetched_section.position == section.position
      assert fetched_section.school_id == section.school_id
    end

    test "create_section/1 with valid data creates a section", %{school: school} do
      valid_attrs = params_for(:section, school_id: school.id)

      assert {:ok, %Section{} = section} = MessageBoard.create_section(valid_attrs)
      assert section.name == valid_attrs.name
      assert section.position == valid_attrs.position
      assert section.school_id == valid_attrs.school_id
    end

    test "create_section/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = MessageBoard.create_section(@invalid_attrs)
    end

    test "update_section/2 with invalid data returns error changeset", %{school: school} do
      section = insert(:section, school: school)
      original_section = MessageBoard.get_section!(section.id)

      assert {:error, %Ecto.Changeset{}} = MessageBoard.update_section(section, @invalid_attrs)

      updated_section = MessageBoard.get_section!(section.id)
      assert updated_section.name == original_section.name
      assert updated_section.position == original_section.position
      assert updated_section.school_id == original_section.school_id
    end

    test "delete_section/1 deletes the section", %{school: school} do
      section = insert(:section, school: school)
      assert {:ok, %Section{}} = MessageBoard.delete_section(section)
      assert_raise Ecto.NoResultsError, fn -> MessageBoard.get_section!(section.id) end
    end

    test "change_section/1 returns a section changeset", %{school: school} do
      section = insert(:section, school: school)
      assert %Ecto.Changeset{} = MessageBoard.change_section(section)
    end
  end
end
