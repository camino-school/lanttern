defmodule Lanttern.PersonalizationTest do
  use Lanttern.DataCase

  alias Lanttern.Personalization

  describe "profile_settings" do
    alias Lanttern.Personalization.ProfileSettings

    import Lanttern.IdentityFixtures

    alias Lanttern.Filters

    test "set_profile_current_filters/2 sets current filters in profile settings" do
      current_profile = staff_member_profile_fixture()

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
      current_profile = staff_member_profile_fixture()

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
  end

  describe "permissions" do
    test "list_valid_permissions/0 returns all valid permissions" do
      valid_permissions = Personalization.list_valid_permissions()

      assert length(valid_permissions) == 3
      assert "students_records_full_access" in valid_permissions
      assert "school_management" in valid_permissions
      assert "content_management" in valid_permissions
    end
  end
end
