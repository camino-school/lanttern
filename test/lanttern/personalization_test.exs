defmodule Lanttern.PersonalizationTest do
  use Lanttern.DataCase

  alias Lanttern.Personalization

  describe "profile_settings" do
    alias Lanttern.Personalization.ProfileSettings

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
