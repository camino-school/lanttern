defmodule LantternWeb.MarkingLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.Assessments
  alias Lanttern.Repo
  alias Lanttern.Schools

  @live_view_path "/strands"

  setup :register_and_log_in_staff_member

  defp prepare(%{user: user}) do
    school = Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
    strand = insert(:strand)
    class = insert(:class, school: school)
    insert(:class_assignment, strand: strand, class: class)

    {:ok, strand: strand, class: class, school: school}
  end

  describe "mount/3 - no class assignments" do
    test "shows prompt to assign classes when strand has no assignments", %{conn: conn} do
      strand = insert(:strand)

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> assert_has("button", text: "Assign classes to strand")
    end
  end

  describe "handle_params/3 - class filter initialization" do
    setup :prepare

    test "shows 'No filters applied' when visiting without classes_ids param", %{
      conn: conn,
      strand: strand
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> assert_has("button", text: "No filters applied")
    end

    test "discards non-assigned classes_ids from URL and defaults to all assigned classes", %{
      conn: conn,
      strand: strand,
      class: class,
      school: school
    } do
      other_class = insert(:class, school: school)

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{other_class.id}")
      |> assert_has("button", text: "1 filter")
      |> within("#strand-assessment-filter-modal", fn session ->
        # the assigned class should be the active selection, not the discarded one
        assert_has(session, "button", text: class.name)
      end)
    end

    test "assessment_view defaults to teacher when param is invalid", %{
      conn: conn,
      strand: strand
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?assessment_view=invalid")
      |> assert_has("button#view-dropdown-button", text: "Assessed by teacher")
    end

    test "respects valid assessment_view URL param", %{conn: conn, strand: strand} do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?assessment_view=student")
      |> assert_has("button#view-dropdown-button", text: "Assessed by students")
    end

    test "hides composition section in modal when strand has no composed APs", %{
      conn: conn,
      strand: strand
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> within("#strand-assessment-filter-modal", fn session ->
        refute_has(session, "p", text: "By grade composition")
      end)
    end
  end

  describe "handle_event/3 toggle_filter_class" do
    setup :prepare

    test "selecting a class and applying shows it as an active filter", %{
      conn: conn,
      strand: strand,
      class: class,
      school: school
    } do
      class2 = insert(:class, school: school)
      insert(:class_assignment, strand: strand, class: class2)

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> within("#strand-assessment-filter-modal", fn session ->
        session
        |> click_button(class.name)
        |> click_button("Save")
      end)
      |> assert_has("button", text: "1 filter")
    end
  end

  describe "handle_event/3 clear_filter_selections" do
    setup :prepare

    test "clears draft class filter state and Save commits the clear", %{
      conn: conn,
      strand: strand,
      class: class
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> within("#strand-assessment-filter-modal", fn session ->
        session
        |> click_button("Clear all filters")
        |> click_button("Save")
      end)
      |> assert_has("button", text: "No filters applied")
    end
  end

  describe "Assessment views" do
    setup %{user: user} do
      school = Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      strand = insert(:strand)
      class = insert(:class, school: school)
      insert(:class_assignment, strand: strand, class: class)

      scale = insert(:scale, school: school, type: "ordinal", breakpoints: [0.4, 0.8])
      ordinal_value_1 = insert(:ordinal_value, scale: scale, name: "ov_1 teacher abc")
      ordinal_value_2 = insert(:ordinal_value, scale: scale, name: "ov_2 student abc")

      assessment_point = insert(:assessment_point, strand_id: strand.id, scale: scale)

      student = insert(:student, school: school) |> Repo.preload(:classes)
      {:ok, student} = Schools.update_student(student, %{classes_ids: [class.id]})

      {:ok, _entry} =
        Assessments.create_assessment_point_entry(%{
          student_id: student.id,
          assessment_point_id: assessment_point.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ordinal_value_1.id,
          student_ordinal_value_id: ordinal_value_2.id
        })

      {:ok,
       strand: strand,
       class: class,
       student: student,
       ordinal_value_1: ordinal_value_1,
       ordinal_value_2: ordinal_value_2}
    end

    test "displays teacher assessment in teacher view", %{
      conn: conn,
      strand: strand,
      class: class,
      student: student,
      ordinal_value_1: ordinal_value_1
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> assert_has("div", text: student.name)
      |> assert_has("div", text: ordinal_value_1.name)
    end

    test "displays student self-assessment in student view", %{
      conn: conn,
      strand: strand,
      class: class,
      student: student,
      ordinal_value_2: ordinal_value_2
    } do
      conn
      |> visit(
        "#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}&assessment_view=student"
      )
      |> assert_has("div", text: student.name)
      |> assert_has("div", text: ordinal_value_2.name)
    end

    test "displays both assessments in compare view", %{
      conn: conn,
      strand: strand,
      class: class,
      student: student,
      ordinal_value_1: ordinal_value_1,
      ordinal_value_2: ordinal_value_2
    } do
      conn
      |> visit(
        "#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}&assessment_view=compare"
      )
      |> assert_has("div", text: student.name)
      |> assert_has("span", text: ordinal_value_1.name)
      |> assert_has("span", text: ordinal_value_2.name)
    end
  end

  describe "handle_event/3 apply_assessment_filters" do
    setup :prepare

    test "adds classes_ids param when a subset of assigned classes is in the filter", %{
      conn: conn,
      strand: strand,
      class: class,
      school: school
    } do
      class2 = insert(:class, school: school)
      insert(:class_assignment, strand: strand, class: class2)

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> within("#strand-assessment-filter-modal", fn session ->
        click_button(session, "Save")
      end)
      |> assert_has("button", text: "1 filter")
    end

    test "removes classes_ids param when the filter matches all assigned classes", %{
      conn: conn,
      strand: strand,
      class: class
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> within("#strand-assessment-filter-modal", fn session ->
        click_button(session, "Save")
      end)
      |> assert_has("button", text: "No filters applied")
    end

    test "removes classes_ids param when no filter classes are selected", %{
      conn: conn,
      strand: strand
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> within("#strand-assessment-filter-modal", fn session ->
        click_button(session, "Save")
      end)
      |> assert_has("button", text: "No filters applied")
    end
  end

  describe "filter by grade composition" do
    setup %{user: user} do
      school = Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      strand = insert(:strand)
      class = insert(:class, school: school)
      insert(:class_assignment, strand: strand, class: class)

      parent_ap =
        insert(:assessment_point,
          strand_id: strand.id,
          name: "Composition AP",
          uses_composition: true
        )

      component_ap_1 =
        insert(:assessment_point, strand_id: strand.id, name: "Component AP 1")

      component_ap_2 =
        insert(:assessment_point, strand_id: strand.id, name: "Component AP 2")

      insert(:assessment_point_component, parent: parent_ap, component: component_ap_1)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap_2)

      {:ok,
       strand: strand,
       class: class,
       parent_ap: parent_ap,
       component_ap_1: component_ap_1,
       component_ap_2: component_ap_2}
    end

    test "shows composition section in modal when strand has composed APs", %{
      conn: conn,
      strand: strand,
      parent_ap: parent_ap
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> within("#strand-assessment-filter-modal", fn session ->
        session
        |> assert_has("p", text: "By grade composition")
        |> assert_has("button", text: parent_ap.name)
      end)
    end

    test "selecting a composition AP and saving adds the composition_ap_id param", %{
      conn: conn,
      strand: strand,
      parent_ap: parent_ap
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> within("#strand-assessment-filter-modal", fn session ->
        session
        |> click_button(parent_ap.name)
        |> click_button("Save")
      end)
      |> assert_has("button", text: "1 filter")
    end

    test "visiting with composition_ap_id param shows filter as active", %{
      conn: conn,
      strand: strand,
      parent_ap: parent_ap
    } do
      conn
      |> visit(
        "#{@live_view_path}/#{strand.id}/assessment/marking?composition_ap_id=#{parent_ap.id}"
      )
      |> assert_has("button", text: "1 filter")
    end

    test "clear_filter_selections clears composition selection and Save removes param", %{
      conn: conn,
      strand: strand,
      parent_ap: parent_ap
    } do
      conn
      |> visit(
        "#{@live_view_path}/#{strand.id}/assessment/marking?composition_ap_id=#{parent_ap.id}"
      )
      |> within("#strand-assessment-filter-modal", fn session ->
        session
        |> click_button("Clear all filters")
        |> click_button("Save")
      end)
      |> assert_has("button", text: "No filters applied")
    end

    test "both class and composition filters active show '2 filters'", %{
      conn: conn,
      strand: strand,
      class: class,
      parent_ap: parent_ap
    } do
      conn
      |> visit(
        "#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}&composition_ap_id=#{parent_ap.id}"
      )
      |> assert_has("button", text: "2 filters")
    end
  end

  describe "command palette" do
    setup %{user: user} do
      school = Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      strand = insert(:strand)
      class = insert(:class, school: school)
      insert(:class_assignment, strand: strand, class: class)

      student = insert(:student, school: school) |> Repo.preload(:classes)
      {:ok, _student} = Schools.update_student(student, %{classes_ids: [class.id]})

      parent_ap =
        insert(:assessment_point,
          strand_id: strand.id,
          name: "Composition AP",
          uses_composition: true
        )

      component_ap =
        insert(:assessment_point, strand_id: strand.id, name: "Component AP")

      plain_ap =
        insert(:assessment_point, strand_id: strand.id, name: "Plain AP")

      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      {:ok,
       strand: strand,
       class: class,
       parent_ap: parent_ap,
       component_ap: component_ap,
       plain_ap: plain_ap}
    end

    test "command palette of an AP part of a composition opens with add composition button disabled",
         %{conn: conn, strand: strand, class: class} do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> within("#grid-assessment-points", &click_button(&1, "Component AP"))
      |> assert_has("button[disabled]", text: "Add grade composition")
      |> assert_has("p", text: "part of another grade composition")
      |> assert_has("li", text: "Composition AP")
    end

    test "command palette of a plain AP opens with an enabled add composition button", %{
      conn: conn,
      strand: strand,
      class: class
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> within("#grid-assessment-points", &click_button(&1, "Plain AP"))
      |> assert_has("button", text: "Add grade composition")
      |> refute_has("button[disabled]", text: "Add grade composition")
    end

    test "command palette of a composed AP opens with the manage composition button", %{
      conn: conn,
      strand: strand,
      class: class
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> within("#grid-assessment-points", &click_button(&1, "Composition AP"))
      |> assert_has("button", text: "Manage grade composition")
    end
  end
end
