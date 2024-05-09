defmodule Lanttern.FiltersTest do
  use Lanttern.DataCase

  alias Lanttern.Filters

  describe "profile_strand_filters" do
    alias Lanttern.Filters.ProfileStrandFilter

    import Lanttern.FiltersFixtures
    alias Lanttern.IdentityFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{profile_id: nil}

    test "list_profile_strand_filters/0 returns all profile_strand_filters" do
      profile_strand_filter = profile_strand_filter_fixture()
      assert Filters.list_profile_strand_filters() == [profile_strand_filter]
    end

    test "list_profile_strand_filters_classes_ids/2 returns all classes ids filtered by profile in the strand context" do
      strand = LearningContextFixtures.strand_fixture()
      class_1 = SchoolsFixtures.class_fixture()
      class_2 = SchoolsFixtures.class_fixture()
      profile = IdentityFixtures.teacher_profile_fixture()

      profile_strand_filter_fixture(%{
        profile_id: profile.id,
        strand_id: strand.id,
        class_id: class_1.id
      })

      profile_strand_filter_fixture(%{
        profile_id: profile.id,
        strand_id: strand.id,
        class_id: class_2.id
      })

      # extra fixtures to test filter
      profile_strand_filter_fixture()

      assert expected =
               Filters.list_profile_strand_filters_classes_ids(profile.id, strand.id)

      assert length(expected) == 2
      assert class_1.id in expected
      assert class_2.id in expected
    end

    test "get_profile_strand_filter!/1 returns the profile_strand_filter with given id" do
      profile_strand_filter = profile_strand_filter_fixture()

      assert Filters.get_profile_strand_filter!(profile_strand_filter.id) ==
               profile_strand_filter
    end

    test "set_profile_strand_filters/3 sets current filters in profile strand filters" do
      current_profile = IdentityFixtures.teacher_profile_fixture()
      strand = LearningContextFixtures.strand_fixture()
      class_1 = SchoolsFixtures.class_fixture()
      class_2 = SchoolsFixtures.class_fixture()

      assert {:ok, results} =
               Filters.set_profile_strand_filters(
                 %{current_profile: current_profile},
                 strand.id,
                 %{classes_ids: [class_1.id, class_2.id]}
               )

      for {_, profile_strand_filter} <- results do
        assert profile_strand_filter.profile_id == current_profile.id
        assert profile_strand_filter.strand_id == strand.id
        assert profile_strand_filter.class_id in [class_1.id, class_2.id]
      end

      # repeat with a new class to test filter "update"
      class_3 = SchoolsFixtures.class_fixture()
      class_3_id = class_3.id

      assert {:ok, _results} =
               Filters.set_profile_strand_filters(
                 %{current_profile: current_profile},
                 strand.id,
                 %{classes_ids: [class_3_id]}
               )

      assert [class_3_id] ==
               Filters.list_profile_strand_filters_classes_ids(
                 current_profile.id,
                 strand.id
               )
    end

    test "create_profile_strand_filter/1 with valid data creates a profile_strand_filter" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()
      strand = Lanttern.LearningContextFixtures.strand_fixture()
      class = Lanttern.SchoolsFixtures.class_fixture()

      valid_attrs = %{profile_id: profile.id, strand_id: strand.id, class_id: class.id}

      assert {:ok, %ProfileStrandFilter{} = profile_strand_filter} =
               Filters.create_profile_strand_filter(valid_attrs)

      assert profile_strand_filter.profile_id == profile.id
      assert profile_strand_filter.strand_id == strand.id
      assert profile_strand_filter.class_id == class.id
    end

    test "create_profile_strand_filter/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Filters.create_profile_strand_filter(@invalid_attrs)
    end

    test "update_profile_strand_filter/2 with valid data updates the profile_strand_filter" do
      profile_strand_filter = profile_strand_filter_fixture()
      strand = Lanttern.LearningContextFixtures.strand_fixture()
      update_attrs = %{strand_id: strand.id}

      assert {:ok, %ProfileStrandFilter{} = profile_strand_filter} =
               Filters.update_profile_strand_filter(profile_strand_filter, update_attrs)

      assert profile_strand_filter.strand_id == strand.id
    end

    test "update_profile_strand_filter/2 with invalid data returns error changeset" do
      profile_strand_filter = profile_strand_filter_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Filters.update_profile_strand_filter(profile_strand_filter, @invalid_attrs)

      assert profile_strand_filter ==
               Filters.get_profile_strand_filter!(profile_strand_filter.id)
    end

    test "delete_profile_strand_filter/1 deletes the profile_strand_filter" do
      profile_strand_filter = profile_strand_filter_fixture()

      assert {:ok, %ProfileStrandFilter{}} =
               Filters.delete_profile_strand_filter(profile_strand_filter)

      assert_raise Ecto.NoResultsError, fn ->
        Filters.get_profile_strand_filter!(profile_strand_filter.id)
      end
    end

    test "change_profile_strand_filter/1 returns a profile_strand_filter changeset" do
      profile_strand_filter = profile_strand_filter_fixture()

      assert %Ecto.Changeset{} =
               Filters.change_profile_strand_filter(profile_strand_filter)
    end
  end

  describe "profile_report_card_filter" do
    alias Lanttern.Filters.ProfileReportCardFilter

    import Lanttern.FiltersFixtures
    alias Lanttern.IdentityFixtures
    alias Lanttern.ReportingFixtures
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{profile_id: nil}

    test "list_profile_report_card_filter/0 returns all profile_report_card_filter" do
      profile_report_card_filter = profile_report_card_filter_fixture()
      assert Filters.list_profile_report_card_filter() == [profile_report_card_filter]
    end

    test "list_profile_report_card_filters/2 returns all classes ids filtered by profile in the report card context" do
      report_card = ReportingFixtures.report_card_fixture()
      class_1 = SchoolsFixtures.class_fixture()
      class_2 = SchoolsFixtures.class_fixture()
      profile = IdentityFixtures.teacher_profile_fixture()

      profile_report_card_filter_fixture(%{
        profile_id: profile.id,
        report_card_id: report_card.id,
        class_id: class_1.id
      })

      profile_report_card_filter_fixture(%{
        profile_id: profile.id,
        report_card_id: report_card.id,
        class_id: class_2.id
      })

      profile_report_card_filter_fixture(%{
        profile_id: profile.id,
        report_card_id: report_card.id,
        class_id: nil,
        linked_students_class_id: class_2.id
      })

      # extra fixtures to test filter
      profile_report_card_filter_fixture()

      assert %{
               classes_ids: expected_classes_ids,
               linked_students_classes_ids: expected_linked_students_classes_ids
             } =
               Filters.list_profile_report_card_filters(
                 profile.id,
                 report_card.id
               )

      assert length(expected_classes_ids) == 2
      assert class_1.id in expected_classes_ids
      assert class_2.id in expected_classes_ids
      assert [class_2.id] == expected_linked_students_classes_ids
    end

    test "get_profile_report_card_filter!/1 returns the profile_report_card_filter with given id" do
      profile_report_card_filter = profile_report_card_filter_fixture()

      assert Filters.get_profile_report_card_filter!(profile_report_card_filter.id) ==
               profile_report_card_filter
    end

    test "set_profile_report_card_filters/3 sets current filters in profile report card filters" do
      current_profile = IdentityFixtures.teacher_profile_fixture()
      report_card = ReportingFixtures.report_card_fixture()
      class_1 = SchoolsFixtures.class_fixture()
      class_2 = SchoolsFixtures.class_fixture()

      assert {:ok, results} =
               Filters.set_profile_report_card_filters(
                 %{current_profile: current_profile},
                 report_card.id,
                 %{
                   classes_ids: [class_1.id, class_2.id],
                   linked_students_classes_ids: [class_1.id]
                 }
               )

      assert length(Map.keys(results)) == 3

      for {_, profile_report_card_filter} <- results do
        assert profile_report_card_filter.profile_id == current_profile.id
        assert profile_report_card_filter.report_card_id == report_card.id

        assert profile_report_card_filter.class_id in [class_1.id, class_2.id] or
                 profile_report_card_filter.linked_students_class_id == class_1.id
      end

      # repeat with a new class to test filter "update"
      class_3 = SchoolsFixtures.class_fixture()
      class_3_id = class_3.id

      assert {:ok, _results} =
               Filters.set_profile_report_card_filters(
                 %{current_profile: current_profile},
                 report_card.id,
                 %{classes_ids: [class_3_id]}
               )

      assert %{classes_ids: [class_3_id], linked_students_classes_ids: [class_1.id]} ==
               Filters.list_profile_report_card_filters(
                 current_profile.id,
                 report_card.id
               )
    end

    test "create_profile_report_card_filter/1 with valid data creates a profile_report_card_filter" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()
      report_card = Lanttern.ReportingFixtures.report_card_fixture()
      class = Lanttern.SchoolsFixtures.class_fixture()

      valid_attrs = %{
        profile_id: profile.id,
        report_card_id: report_card.id,
        class_id: class.id
      }

      assert {:ok, %ProfileReportCardFilter{} = profile_report_card_filter} =
               Filters.create_profile_report_card_filter(valid_attrs)

      assert profile_report_card_filter.profile_id == profile.id
      assert profile_report_card_filter.report_card_id == report_card.id
      assert profile_report_card_filter.class_id == class.id
    end

    test "create_profile_report_card_filter/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Filters.create_profile_report_card_filter(@invalid_attrs)
    end

    test "update_profile_report_card_filter/2 with valid data updates the profile_report_card_filter" do
      profile_report_card_filter = profile_report_card_filter_fixture()
      class = Lanttern.SchoolsFixtures.class_fixture()
      update_attrs = %{class_id: class.id}

      assert {:ok, %ProfileReportCardFilter{} = profile_report_card_filter} =
               Filters.update_profile_report_card_filter(
                 profile_report_card_filter,
                 update_attrs
               )

      assert profile_report_card_filter.class_id == class.id
    end

    test "update_profile_report_card_filter/2 with invalid data returns error changeset" do
      profile_report_card_filter = profile_report_card_filter_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Filters.update_profile_report_card_filter(
                 profile_report_card_filter,
                 @invalid_attrs
               )

      assert profile_report_card_filter ==
               Filters.get_profile_report_card_filter!(profile_report_card_filter.id)
    end

    test "delete_profile_report_card_filter/1 deletes the profile_report_card_filter" do
      profile_report_card_filter = profile_report_card_filter_fixture()

      assert {:ok, %ProfileReportCardFilter{}} =
               Filters.delete_profile_report_card_filter(profile_report_card_filter)

      assert_raise Ecto.NoResultsError, fn ->
        Filters.get_profile_report_card_filter!(profile_report_card_filter.id)
      end
    end

    test "change_profile_report_card_filter/1 returns a profile_report_card_filter changeset" do
      profile_report_card_filter = profile_report_card_filter_fixture()

      assert %Ecto.Changeset{} =
               Filters.change_profile_report_card_filter(profile_report_card_filter)
    end
  end
end
