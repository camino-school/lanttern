defmodule LantternWeb.AssessmentPointLive.DetailsTest do
  use LantternWeb.ConnCase

  alias Lanttern.Repo
  alias Lanttern.AssessmentsFixtures
  alias Lanttern.ConversationFixtures
  alias Lanttern.CurriculaFixtures
  alias Lanttern.GradingFixtures
  alias Lanttern.SchoolsFixtures

  @live_view_path_base "/assessment_points"
  @overlay_selector "#feedback-overlay"

  setup :register_and_log_in_user

  describe "Assessment point details live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      %{id: id} = AssessmentsFixtures.assessment_point_fixture()

      conn = get(conn, "#{@live_view_path_base}/#{id}")
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Assessment point details\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "display assessment point details", %{conn: conn} do
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()
      attrs = %{curriculum_item_id: curriculum_item.id, scale: scale.id}

      %{
        id: id,
        name: name,
        description: description,
        datetime: datetime
      } =
        AssessmentsFixtures.assessment_point_fixture(attrs)

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{id}")

      assert view |> has_element?("h2", name)
      assert view |> has_element?("p", description)

      assert view
             |> has_element?(
               "div",
               Timex.format!(Timex.local(datetime), "{Mshort} {D}, {YYYY}, {h24}:{m}")
             )

      assert view |> has_element?("div", curriculum_item.name)
      assert view |> has_element?("div", scale.name)
    end

    test "overlay shows in live view", %{conn: conn} do
      assessment_point = AssessmentsFixtures.assessment_point_fixture()
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # confirms overlay is not rendered
      refute view
             |> element("h2", "Update assessment point")
             |> has_element?()

      # click button to render
      view
      |> element("a", "Edit")
      |> render_click()

      # assert overlay is rendered
      assert view
             |> element("#update-assessment-point-overlay h2", "Update assessment point")
             |> render() =~ "Update assessment point"
    end

    test "redirect to /assessment_points when supplied id does not exist", %{conn: conn} do
      wrong_id = "1000000"

      {:error, {:redirect, %{to: path, flash: flash}}} =
        live(conn, "#{@live_view_path_base}/#{wrong_id}")

      assert path == "/assessment_points"
      assert flash["error"] == "Couldn't find assessment point"
    end

    test "redirect to /assessment_points when supplied id is string", %{conn: conn} do
      wrong_id = "abcd"

      {:error, {:redirect, %{to: path, flash: flash}}} =
        live(conn, "#{@live_view_path_base}/#{wrong_id}")

      assert path == "/assessment_points"
      assert flash["error"] == "Couldn't find assessment point"
    end
  end

  describe "Assessment point details rubrics" do
    test "rubrics overlay shows in live view", %{conn: conn} do
      assessment_point = AssessmentsFixtures.assessment_point_fixture()
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # confirms overlay is not rendered
      refute view
             |> element("h2", "Assessment point rubrics")
             |> has_element?()

      # click button to render
      view
      |> element("a", "Add rubrics")
      |> render_click()

      # assert overlay is rendered
      assert_patch(view)

      assert view
             |> element("#rubrics-overlay h2", "Assessment point rubrics")
             |> has_element?()
    end

    test "rubrics descriptors show in overlay", %{conn: conn} do
      scale = Lanttern.GradingFixtures.scale_fixture(%{type: "numeric"})
      rubric = Lanttern.RubricsFixtures.rubric_fixture(%{scale_id: scale.id})

      descriptor =
        Lanttern.RubricsFixtures.rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          score: 50
        })

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{rubric_id: rubric.id, scale_id: scale.id})

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}/rubrics")

      assert view
             |> element("#rubrics-overlay p", descriptor.descriptor)
             |> has_element?()
    end

    test "link assessment point to existing rubric in overlay", %{conn: conn} do
      scale = Lanttern.GradingFixtures.scale_fixture(%{type: "numeric"})
      rubric = Lanttern.RubricsFixtures.rubric_fixture(%{scale_id: scale.id})

      descriptor =
        Lanttern.RubricsFixtures.rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          score: 50
        })

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{scale_id: scale.id})

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}/rubrics")

      view
      |> element("#assessment-point-rubric-search")
      |> render_hook("autocomplete_result_select", %{"id" => "#{rubric.id}"})

      assert view
             |> element("#rubrics-overlay p", descriptor.descriptor)
             |> has_element?()

      # assert in DB
      expected = Repo.get(Lanttern.Assessments.AssessmentPoint, assessment_point.id)
      assert expected.rubric_id == rubric.id
    end

    test "create and link rubric to assessment point in overlay", %{conn: conn} do
      scale = Lanttern.GradingFixtures.scale_fixture(%{type: "numeric"})

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{scale_id: scale.id})

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}/rubrics")

      view
      |> element("button", "create a new rubric")
      |> render_click()

      view
      |> element("#rubric-form-new")
      |> render_submit(%{
        "rubric" => %{
          "criteria" => "new rubric abc",
          "scale_id" => scale.id,
          "is_differentiation" => false,
          "descriptors" => %{
            "0" => %{
              "scale_id" => scale.id,
              "scale_type" => scale.type,
              "score" => 0.0,
              "descriptor" => "0 descriptor abc"
            },
            "1" => %{
              "scale_id" => scale.id,
              "scale_type" => scale.type,
              "score" => 100.0,
              "descriptor" => "100 descriptor abc"
            }
          }
        }
      })

      assert view
             |> element("#rubrics-overlay p", "0 descriptor abc")
             |> has_element?()

      assert view
             |> element("#rubrics-overlay p", "100 descriptor abc")
             |> has_element?()

      # assert in DB
      expected = Repo.get(Lanttern.Assessments.AssessmentPoint, assessment_point.id)
      assert expected.rubric_id != nil
    end
  end

  describe "Assessment point details differentiation rubrics" do
    test "differentiation rubrics descriptors show in overlay", %{conn: conn} do
      scale = Lanttern.GradingFixtures.scale_fixture(%{type: "numeric"})

      rubric =
        Lanttern.RubricsFixtures.rubric_fixture(%{scale_id: scale.id, is_differentiation: true})

      descriptor =
        Lanttern.RubricsFixtures.rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          score: 50
        })

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{scale_id: scale.id})

      _entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          scale_id: scale.id,
          scale_type: scale.type,
          differentiation_rubric_id: rubric.id
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}/rubrics")

      assert view
             |> element("#rubrics-overlay p", descriptor.descriptor)
             |> has_element?()
    end

    test "link assessment point entry to existing rubric in overlay", %{conn: conn} do
      scale = Lanttern.GradingFixtures.scale_fixture(%{type: "numeric"})

      rubric =
        Lanttern.RubricsFixtures.rubric_fixture(%{scale_id: scale.id, is_differentiation: true})

      descriptor =
        Lanttern.RubricsFixtures.rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          score: 50
        })

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{scale_id: scale.id})

      entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}/rubrics")

      view
      |> element("#entry-#{entry.id}-rubric-search")
      |> render_hook("autocomplete_result_select", %{"id" => "#{rubric.id}"})

      assert view
             |> element("#rubrics-overlay p", descriptor.descriptor)
             |> has_element?()

      # assert in DB
      expected = Repo.get(Lanttern.Assessments.AssessmentPointEntry, entry.id)
      assert expected.differentiation_rubric_id == rubric.id
    end

    test "create and link differentiation rubric to assessment point entry in overlay", %{
      conn: conn
    } do
      scale =
        Lanttern.GradingFixtures.scale_fixture(%{type: "numeric", is_differenatiation: true})

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{scale_id: scale.id})

      entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}/rubrics")

      view
      |> element("button", "create a new differentiation rubric")
      |> render_click()

      view
      |> element("#rubric-form-entry-#{entry.id}")
      |> render_submit(%{
        "rubric" => %{
          "criteria" => "new rubric abc",
          "scale_id" => scale.id,
          "is_differentiation" => false,
          "descriptors" => %{
            "0" => %{
              "scale_id" => scale.id,
              "scale_type" => scale.type,
              "score" => 0.0,
              "descriptor" => "0 descriptor abc"
            },
            "1" => %{
              "scale_id" => scale.id,
              "scale_type" => scale.type,
              "score" => 100.0,
              "descriptor" => "100 descriptor abc"
            }
          }
        }
      })

      assert view
             |> element("#rubrics-overlay p", "0 descriptor abc")
             |> has_element?()

      assert view
             |> element("#rubrics-overlay p", "100 descriptor abc")
             |> has_element?()

      # assert in DB
      expected = Repo.get(Lanttern.Assessments.AssessmentPointEntry, entry.id)
      assert expected.differentiation_rubric_id != nil
    end
  end

  describe "Assessment point details live view feedback" do
    test "feedback buttons display", %{conn: conn} do
      scale = Lanttern.GradingFixtures.scale_fixture()
      assessment_point = AssessmentsFixtures.assessment_point_fixture(%{scale_id: scale.id})

      std_no_feedback = SchoolsFixtures.student_fixture()
      std_incomplete_feedback = SchoolsFixtures.student_fixture()
      std_completed_feedback = SchoolsFixtures.student_fixture()

      _entry_no_feedback =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: std_no_feedback.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      _entry_incomplete_feedback =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: std_incomplete_feedback.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      _entry_completed_feedback =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: std_completed_feedback.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      _incomplete_feedback =
        AssessmentsFixtures.feedback_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: std_incomplete_feedback.id
        })

      _completed_feedback =
        AssessmentsFixtures.feedback_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: std_completed_feedback.id,
          completion_comment_id: ConversationFixtures.comment_fixture().id
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      assert view |> has_element?("a", "No feedback yet")
      assert view |> has_element?("a", "Not completed yet")
      assert view |> has_element?("a", ~r/Completed [A-Z][a-z]{2} [0-9]{1,2}, [0-9]{4} 🎉/)
    end
  end

  describe "Create new feedback in assessment points live view" do
    setup :create_assessment_point_without_feedback

    test "feedback overlay shows in live view", %{conn: conn, assessment_point: assessment_point} do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # confirms overlay is not rendered
      refute view
             |> element("#{@overlay_selector} h2", "Feedback")
             |> has_element?()

      # click link to render
      view
      |> element("a", "No feedback yet")
      |> render_click()

      # assert overlay is rendered
      assert view
             |> element("#{@overlay_selector} h2", "Feedback")
             |> has_element?()
    end

    test "from/to is based on the current user", %{
      conn: conn,
      assessment_point: assessment_point,
      user: user,
      student: student
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("a", "No feedback yet")
      |> render_click()

      # assert from/to is correct
      {:ok, regex} =
        Regex.compile("From.+#{user.current_profile.teacher.name}.+To.+#{student.name}", "s")

      assert view
             |> element("#{@overlay_selector}", regex)
             |> has_element?()
    end

    defp create_assessment_point_without_feedback(_) do
      scale = Lanttern.GradingFixtures.scale_fixture()
      assessment_point = AssessmentsFixtures.assessment_point_fixture(%{scale_id: scale.id})

      # create assessment point entry to render the student row,
      # which contains the feedback button
      student = SchoolsFixtures.student_fixture()

      _assessment_point_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      %{
        assessment_point: assessment_point,
        student: student
      }
    end
  end

  describe "Display existing feedback in assessment points live view" do
    setup :create_assessment_point_with_feedback

    test "feedback overlay shows in live view", %{conn: conn, assessment_point: assessment_point} do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # confirms overlay is not rendered
      refute view
             |> element("#{@overlay_selector} h2", "Feedback")
             |> has_element?()

      # click link to render
      view
      |> element("a", "Not completed yet")
      |> render_click()

      # assert overlay is rendered
      assert view
             |> element("#{@overlay_selector} h2", "Feedback")
             |> has_element?()
    end

    test "from/to is based on the existing feedback", %{
      conn: conn,
      assessment_point: assessment_point,
      teacher: teacher,
      student: student
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("a", "Not completed yet")
      |> render_click()

      # assert from/to is correct
      {:ok, regex} =
        Regex.compile("From.+#{teacher.name}.+To.+#{student.name}", "s")

      assert view
             |> element("#{@overlay_selector}", regex)
             |> has_element?()
    end

    defp create_assessment_point_with_feedback(_) do
      scale = Lanttern.GradingFixtures.scale_fixture()
      assessment_point = AssessmentsFixtures.assessment_point_fixture(%{scale_id: scale.id})
      student = SchoolsFixtures.student_fixture()

      # create assessment point entry to render the student row,
      # which contains the feedback button

      _assessment_point_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      feedback =
        AssessmentsFixtures.feedback_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: student.id
        })
        |> Repo.preload(profile: :teacher)

      %{
        assessment_point: assessment_point,
        student: student,
        teacher: feedback.profile.teacher,
        feedback: feedback
      }
    end
  end

  describe "Assessment point details markdown support" do
    test "renders HTML correctly", %{conn: conn} do
      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{
          description: """
          paragraph 1 with *italic*

          paragraph 2 with **bold**

          ## h2 heading

          - list item
          """
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      assert view |> has_element?("p", "paragraph 1")
      assert view |> has_element?("em", "italic")
      assert view |> has_element?("p", "paragraph 2")
      assert view |> has_element?("strong", "bold")
      assert view |> has_element?("h2", "h2 heading")
      assert view |> has_element?("li", "list item")
    end
  end
end
