defmodule Lanttern.PersonalizationTest do
  use Lanttern.DataCase

  alias Lanttern.Personalization

  describe "profile_views" do
    alias Lanttern.Personalization.ProfileView

    import Lanttern.PersonalizationFixtures

    @invalid_attrs %{name: nil}

    test "list_profile_views/1 returns all profile_views" do
      profile_view = profile_view_fixture()
      [expected] = Personalization.list_profile_views()
      assert expected.id == profile_view.id
    end

    test "list_profile_views/1 with preloads returns all profile_views with preloaded data" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      profile_view =
        profile_view_fixture(%{profile_id: profile.id})

      [expected] = Personalization.list_profile_views(preloads: :profile)
      assert expected.id == profile_view.id
      assert expected.profile == profile
    end

    test "list_profile_views/1 with profile filter returns all profile_views belonging to given profile" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      profile_view =
        profile_view_fixture(%{profile_id: profile.id})

      # extra fixture for filter testing
      profile_view_fixture()

      [expected] = Personalization.list_profile_views(profile_id: profile.id)
      assert expected.id == profile_view.id
    end

    test "get_profile_view!/2 returns the profile_view with given id" do
      profile_view = profile_view_fixture()

      expected = Personalization.get_profile_view!(profile_view.id)
      assert expected.id == profile_view.id
    end

    test "get_profile_view!/2 with preloads returns the profile_view with given id with preloaded data" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      profile_view =
        profile_view_fixture(%{profile_id: profile.id})

      expected =
        Personalization.get_profile_view!(profile_view.id,
          preloads: :profile
        )

      assert expected.id == profile_view.id
      assert expected.profile == profile
    end

    test "create_profile_view/1 with valid data creates a profile_view" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()
      subject = Lanttern.TaxonomyFixtures.subject_fixture()
      class = Lanttern.SchoolsFixtures.class_fixture()

      valid_attrs = %{
        name: "some name",
        profile_id: profile.id,
        subjects_ids: [subject.id],
        classes_ids: [class.id]
      }

      assert {:ok, %ProfileView{} = profile_view} =
               Personalization.create_profile_view(valid_attrs)

      assert profile_view.name == "some name"

      # assert subject and class relationship were created

      assert [{profile_view.id, subject.id}] ==
               from(
                 vs in "profile_views_subjects",
                 where: vs.profile_view_id == ^profile_view.id,
                 select: {vs.profile_view_id, vs.subject_id}
               )
               |> Repo.all()

      assert [{profile_view.id, class.id}] ==
               from(
                 vc in "profile_views_classes",
                 where: vc.profile_view_id == ^profile_view.id,
                 select: {vc.profile_view_id, vc.class_id}
               )
               |> Repo.all()
    end

    test "create_profile_view/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Personalization.create_profile_view(@invalid_attrs)
    end

    test "update_profile_view/2 with valid data updates the profile_view" do
      profile_view = profile_view_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %ProfileView{} = profile_view} =
               Personalization.update_profile_view(
                 profile_view,
                 update_attrs
               )

      assert profile_view.name == "some updated name"
    end

    test "update_profile_view/2 with invalid data returns error changeset" do
      profile_view = profile_view_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Personalization.update_profile_view(
                 profile_view,
                 @invalid_attrs
               )

      expected = Personalization.get_profile_view!(profile_view.id)
      assert expected.id == profile_view.id
      assert expected.name == profile_view.name
    end

    test "delete_profile_view/1 deletes the profile_view" do
      profile_view = profile_view_fixture()

      assert {:ok, %ProfileView{}} =
               Personalization.delete_profile_view(profile_view)

      assert_raise Ecto.NoResultsError, fn ->
        Personalization.get_profile_view!(profile_view.id)
      end
    end

    test "change_profile_view/1 returns a profile_view changeset" do
      profile_view = profile_view_fixture()

      assert %Ecto.Changeset{} =
               Personalization.change_profile_view(profile_view)
    end
  end

  describe "profile_settings" do
    alias Lanttern.Personalization.ProfileSettings

    import Lanttern.PersonalizationFixtures
    import Lanttern.IdentityFixtures

    alias Lanttern.Filters

    test "set_profile_current_filters/2 sets current filters in profile settings" do
      current_profile = teacher_profile_fixture()

      subjects_ids = [1, 2, 3]
      classes_ids = [4, 5, 6]

      assert {:ok, %ProfileSettings{} = settings} =
               Filters.set_profile_current_filters(
                 %{current_profile: current_profile},
                 %{
                   subjects_ids: subjects_ids,
                   classes_ids: classes_ids
                 }
               )

      assert settings.current_filters.subjects_ids == subjects_ids
      assert settings.current_filters.classes_ids == classes_ids
    end

    test "set_profile_current_filters/2 with only one type of filter keeps the other filters as is" do
      current_profile = teacher_profile_fixture()

      # create profile settings with classes ids
      Filters.set_profile_current_filters(
        %{current_profile: current_profile},
        %{classes_ids: [4, 5, 6]}
      )

      subjects_ids = [1, 2, 3]

      assert {:ok, %ProfileSettings{} = settings} =
               Filters.set_profile_current_filters(
                 %{current_profile: current_profile},
                 %{subjects_ids: subjects_ids}
               )

      assert settings.current_filters.subjects_ids == subjects_ids
      assert settings.current_filters.classes_ids == [4, 5, 6]
    end

    test "sync_params_and_profile_filters/3 when there's no current filters in profile sets current filters based on params" do
      current_profile = teacher_profile_fixture()

      params = %{"foo" => "bar", "classes_ids" => ["1", "2", "3"]}

      {:noop, expected} =
        Filters.sync_params_and_profile_filters(
          params,
          %{current_profile: current_profile},
          [:classes_ids]
        )

      assert expected["foo"] == "bar"
      assert expected["classes_ids"] == ["1", "2", "3"]

      profile_settings = Personalization.get_profile_settings(current_profile.id)

      assert profile_settings.current_filters.classes_ids == [1, 2, 3]
    end

    test "sync_params_and_profile_filters/3 when there's no params updates params with profile filters " do
      current_profile = teacher_profile_fixture()

      # create profile settings with classes ids
      Filters.set_profile_current_filters(
        %{current_profile: current_profile},
        %{classes_ids: [4, 5, 6]}
      )

      params = %{"foo" => "bar"}

      {:updated, expected} =
        Filters.sync_params_and_profile_filters(
          params,
          %{current_profile: current_profile},
          [:classes_ids]
        )

      assert expected["foo"] == "bar"
      assert expected["classes_ids"] == ["4", "5", "6"]
    end

    test "sync_params_and_profile_filters/3 adds params to filters and filters to params" do
      current_profile = teacher_profile_fixture()

      # create profile settings with classes and years ids
      Filters.set_profile_current_filters(
        %{current_profile: current_profile},
        %{classes_ids: [4, 5, 6], years_ids: [7, 8, 9]}
      )

      params = %{"foo" => "bar", "subjects_ids" => ["1", "2", "3"], "years_ids" => ""}

      {:updated, expected} =
        Filters.sync_params_and_profile_filters(
          params,
          %{current_profile: current_profile},
          [:classes_ids, :subjects_ids, :years_ids]
        )

      assert expected["foo"] == "bar"
      assert expected["subjects_ids"] == ["1", "2", "3"]
      assert expected["classes_ids"] == ["4", "5", "6"]
      assert expected["years_ids"] == ""

      profile_settings = Personalization.get_profile_settings(current_profile.id)

      assert profile_settings.current_filters.subjects_ids == [1, 2, 3]
      assert profile_settings.current_filters.classes_ids == [4, 5, 6]
      assert profile_settings.current_filters.years_ids == []
    end
  end
end
