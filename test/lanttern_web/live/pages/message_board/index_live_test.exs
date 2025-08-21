defmodule LantternWeb.MessageBoard.IndexLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  describe "Message board liveview as Staff" do
    setup [:register_and_log_in_staff_member]

    test "list only filter classes", ctx do
      school = ctx.user.current_profile.staff_member.school
      cycle = ctx.user.current_profile.current_school_cycle
      class = insert(:class, %{school: school, cycle: cycle})
      attrs = %{school: school, send_to: "classes", classes_ids: [class.id]}
      section = insert(:section, %{school: school})

      message = insert(:message, attrs)

      archived =
        insert(:message, %{
          school: school,
          section: section,
          name: "archived message abc",
          description: "archived message desc abc",
          archived_at: DateTime.utc_now()
        })

      m2 = insert(:message, %{section: section, school: school})

      Lanttern.Filters.set_profile_current_filters(ctx.user, %{classes_ids: [class.id]})

      ctx.conn
      |> visit("/school/message_board")
      |> assert_has("h1", text: "Message board admin")
      |> refute_has("h3", text: message.name)
      |> assert_has("h3", text: m2.name)
      |> assert_has("button", text: class.name)
      |> refute_has("h3", text: archived.name)
    end

    test "create a new message", ctx do
      %{conn: conn} = set_user_permissions(["communication_management"], ctx)
      attr = %{name: "test message", description: "test description", color: "CBCBCB"}
      insert(:section, %{school: ctx.user.current_profile.staff_member.school})

      conn
      |> visit("/school/message_board")
      |> assert_has("h1", text: "Message board admin")
      |> click_link("Add new message")
      |> fill_in("Message title", with: attr.name)
      |> fill_in("Description", with: attr.description)
      |> fill_in("Card color", with: attr.color)
      |> click_button("Save")

      conn
      |> visit("/school/message_board")
      |> assert_has("h3", text: attr.name)
    end

    test "prevent user w/o permission to create a message", ctx do
      section = insert(:section)

      ctx.conn
      |> visit("/school/message_board?new=true&section_id=#{section.id}")
      |> refute_has("h2", text: "New message")
    end

    test "edit a existing message", ctx do
      %{conn: conn} = set_user_permissions(["communication_management"], ctx)
      school = ctx.user.current_profile.staff_member.school
      section = insert(:section, %{school: school})
      message = insert(:message, %{school: school, section: section})
      attrs = %{name: "edited name"}

      conn
      |> visit("/school/message_board")
      |> assert_has("h3", text: message.name)
      |> click_link("#message-#{message.id}-edit", "")
      |> fill_in("Message title", with: attrs.name)
      |> click_button("Save")

      conn
      |> visit("/school/message_board")
      |> assert_has("h3", text: attrs.name)
    end

    test "prevent user w/o permission to edit a message", ctx do
      message = insert(:message, %{name: "message from other school"})

      ctx.conn
      |> visit("/school/message_board?edit=#{message.id}")
      |> refute_has("h2", text: "Edit message")
    end

    test "create a new section w/ permissions", ctx do
      %{conn: conn} = set_user_permissions(["communication_management"], ctx)
      attr = %{name: "test section"}

      conn
      |> visit("/school/message_board")
      |> assert_has("h1", text: "Message board admin")
      |> click_link("Create section")
      |> fill_in("Section name", with: attr.name)
      |> click_button("Save")

      conn
      |> visit("/school/message_board")
      |> assert_has("h2", text: attr.name)
    end

    test "edit a existing section w/ permissions", ctx do
      %{conn: conn} = set_user_permissions(["communication_management"], ctx)
      school = ctx.user.current_profile.staff_member.school
      attr = %{name: "test section"}
      section = insert(:section, %{name: "old title", school: school})

      conn
      |> visit("/school/message_board")
      |> assert_has("h1", text: "Message board admin")
      |> click_link("#section-#{section.id}-settings", "Settings")
      |> fill_in("Section name", with: attr.name)
      |> click_button("Save")

      conn
      |> visit("/school/message_board")
      |> assert_has("h2", text: attr.name)
    end

    test "delete a existing section w/ permissions", ctx do
      %{conn: conn} = set_user_permissions(["communication_management"], ctx)
      school = ctx.user.current_profile.staff_member.school
      section = insert(:section, %{name: "section to delete", school: school})

      conn
      |> visit("/school/message_board")
      |> assert_has("h2", text: section.name)
      |> click_link("#section-#{section.id}-settings", "Settings")
      |> click_button("Delete")

      conn
      |> visit("/school/message_board")
      |> refute_has("h2", text: section.name)
    end

    test "reorder a existing message", ctx do
      %{conn: conn} = set_user_permissions(["communication_management"], ctx)
      school = ctx.user.current_profile.staff_member.school
      section = insert(:section, %{school: school})
      message1 = insert(:message, %{section: section, school: school})
      message2 = insert(:message, %{section: section, school: school})
      message3 = insert(:message, %{section: section, school: school})

      conn
      |> visit("/school/message_board")
      |> tap(fn %{view: view} ->
        assert render(view) =~ ~r/#{message1.name}.*#{message2.name}.*#{message3.name}/s
      end)
      |> click_link("#section-#{section.id}-settings", "Settings")
      |> tap(fn %{view: view} ->
        assert render_hook(view, "sortable_update", %{"oldIndex" => 0, "newIndex" => 2})
      end)
      |> tap(fn %{view: view} ->
        assert render(view) =~ ~r/#{message2.name}.*#{message3.name}.*#{message1.name}/s
      end)
    end

    test "reorder a existing section", ctx do
      %{conn: conn} = set_user_permissions(["communication_management"], ctx)
      school = ctx.user.current_profile.staff_member.school
      section1 = insert(:section, %{school: school})
      section2 = insert(:section, %{school: school})

      conn
      |> visit("/school/message_board/")
      |> click_link("Reorder sections")
      |> tap(fn %{current_path: path} -> assert path == "/school/message_board/reorder" end)
      |> assert_has("h1", text: "Message board admin - Reorder sections")
      |> tap(fn %{view: view} ->
        assert render(view) =~ ~r/#{section1.name}.*#{section2.name}/s
        assert render_hook(view, "sortable_update", %{"oldIndex" => 0, "newIndex" => 1})
      end)
      |> click_link("Manage messages")
      |> tap(fn %{current_path: path} -> assert path == "/school/message_board" end)
      |> tap(fn %{view: view} ->
        assert render(view) =~ ~r/#{section2.name}.*#{section1.name}/s
      end)
    end

    test "include attachments to a existing message", ctx do
      %{conn: conn} = set_user_permissions(["communication_management"], ctx)
      school = ctx.user.current_profile.staff_member.school
      section = insert(:section, %{school: school})
      message = insert(:message, %{school: school, section: section})

      conn
      |> visit("/school/message_board")
      |> assert_has("h3", text: message.name)
      |> click_link("#message-#{message.id} a", "")
      |> assert_has("h2", text: "Edit message")
      |> click_button(
        "#message-attachments-external-link-button",
        "Or add a link to an external file"
      )
      |> fill_in("Attachment name", with: "News")
      |> fill_in("Link", with: "http://www.science.org/article-1")
      |> submit()
      |> assert_has("a", text: "News")
      |> click_button(".block.w-full", "Edit")
      |> fill_in("Attachment name", with: "Article2")
      |> fill_in("Link", with: "http://www.science.org/article-2")
      |> submit()
      |> assert_has("a", text: "Article2")
      |> refute_has("a", text: "News")
    end

    # @tag :skip
    # test "show message to student and guardian" do
    #   # login with profile
    # end

    # @tag :skip
    # test "show message to student in specific class" do
    #   # create a class
    #   # login with profile, assoc to class
    # end

    # @tag :skip
    # test "show message to guardian in specific class" do
    #   # create a class
    #   # login with profile, assoc to class
    # end
  end
end
