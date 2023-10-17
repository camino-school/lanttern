defmodule Lanttern.ExplorerTest do
  use Lanttern.DataCase

  alias Lanttern.Explorer
  alias Lanttern.Repo
  import Ecto.Query, only: [from: 2]

  describe "assessment_points_filter_views" do
    alias Lanttern.Explorer.AssessmentPointsFilterView

    import Lanttern.ExplorerFixtures

    @invalid_attrs %{name: nil}

    test "list_assessment_points_filter_views/1 returns all assessment_points_filter_views" do
      assessment_points_filter_view = assessment_points_filter_view_fixture()
      assert Explorer.list_assessment_points_filter_views() == [assessment_points_filter_view]
    end

    test "list_assessment_points_filter_views/1 with preloads returns all assessment_points_filter_views with preloaded data" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      assessment_points_filter_view =
        assessment_points_filter_view_fixture(%{profile_id: profile.id})

      [expected] = Explorer.list_assessment_points_filter_views(preloads: :profile)
      assert expected.id == assessment_points_filter_view.id
      assert expected.profile == profile
    end

    test "list_assessment_points_filter_views/1 with profile filter returns all assessment_points_filter_views belonging to given profile" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      assessment_points_filter_view =
        assessment_points_filter_view_fixture(%{profile_id: profile.id})

      # extra fixture for filter testing
      assessment_points_filter_view_fixture()

      [expected] = Explorer.list_assessment_points_filter_views(profile_id: profile.id)
      assert expected.id == assessment_points_filter_view.id
    end

    test "get_assessment_points_filter_view!/2 returns the assessment_points_filter_view with given id" do
      assessment_points_filter_view = assessment_points_filter_view_fixture()

      assert Explorer.get_assessment_points_filter_view!(assessment_points_filter_view.id) ==
               assessment_points_filter_view
    end

    test "get_assessment_points_filter_view!/2 with preloads returns the assessment_points_filter_view with given id with preloaded data" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      assessment_points_filter_view =
        assessment_points_filter_view_fixture(%{profile_id: profile.id})

      expected =
        Explorer.get_assessment_points_filter_view!(assessment_points_filter_view.id,
          preloads: :profile
        )

      assert expected.id == assessment_points_filter_view.id
      assert expected.profile == profile
    end

    test "create_assessment_points_filter_view/1 with valid data creates a assessment_points_filter_view" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()
      subject = Lanttern.TaxonomyFixtures.subject_fixture()
      class = Lanttern.SchoolsFixtures.class_fixture()

      valid_attrs = %{
        name: "some name",
        profile_id: profile.id,
        subjects_ids: [subject.id],
        classes_ids: [class.id]
      }

      assert {:ok, %AssessmentPointsFilterView{} = assessment_points_filter_view} =
               Explorer.create_assessment_points_filter_view(valid_attrs)

      assert assessment_points_filter_view.name == "some name"

      # assert subject and class relationship were created

      assert [{assessment_points_filter_view.id, subject.id}] ==
               from(
                 vs in "assessment_points_filter_views_subjects",
                 where: vs.assessment_points_filter_view_id == ^assessment_points_filter_view.id,
                 select: {vs.assessment_points_filter_view_id, vs.subject_id}
               )
               |> Repo.all()

      assert [{assessment_points_filter_view.id, class.id}] ==
               from(
                 vc in "assessment_points_filter_views_classes",
                 where: vc.assessment_points_filter_view_id == ^assessment_points_filter_view.id,
                 select: {vc.assessment_points_filter_view_id, vc.class_id}
               )
               |> Repo.all()
    end

    test "create_assessment_points_filter_view/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Explorer.create_assessment_points_filter_view(@invalid_attrs)
    end

    test "update_assessment_points_filter_view/2 with valid data updates the assessment_points_filter_view" do
      assessment_points_filter_view = assessment_points_filter_view_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %AssessmentPointsFilterView{} = assessment_points_filter_view} =
               Explorer.update_assessment_points_filter_view(
                 assessment_points_filter_view,
                 update_attrs
               )

      assert assessment_points_filter_view.name == "some updated name"
    end

    test "update_assessment_points_filter_view/2 with invalid data returns error changeset" do
      assessment_points_filter_view = assessment_points_filter_view_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Explorer.update_assessment_points_filter_view(
                 assessment_points_filter_view,
                 @invalid_attrs
               )

      assert assessment_points_filter_view ==
               Explorer.get_assessment_points_filter_view!(assessment_points_filter_view.id)
    end

    test "delete_assessment_points_filter_view/1 deletes the assessment_points_filter_view" do
      assessment_points_filter_view = assessment_points_filter_view_fixture()

      assert {:ok, %AssessmentPointsFilterView{}} =
               Explorer.delete_assessment_points_filter_view(assessment_points_filter_view)

      assert_raise Ecto.NoResultsError, fn ->
        Explorer.get_assessment_points_filter_view!(assessment_points_filter_view.id)
      end
    end

    test "change_assessment_points_filter_view/1 returns a assessment_points_filter_view changeset" do
      assessment_points_filter_view = assessment_points_filter_view_fixture()

      assert %Ecto.Changeset{} =
               Explorer.change_assessment_points_filter_view(assessment_points_filter_view)
    end
  end
end