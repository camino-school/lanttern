defmodule Lanttern.LearningContextTest do
  use Lanttern.DataCase

  alias Lanttern.LearningContext
  import Lanttern.LearningContextFixtures

  describe "strands" do
    alias Lanttern.LearningContext.Strand

    import Lanttern.TaxonomyFixtures
    import Lanttern.CurriculaFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_strands/1 returns all strands ordered alphabetically" do
      strand_a = strand_fixture(%{name: "AAA"})
      strand_c = strand_fixture(%{name: "CCC"})
      strand_b = strand_fixture(%{name: "BBB"})

      assert LearningContext.list_strands() == [strand_a, strand_b, strand_c]
    end

    test "list_strands/1 with preloads returns all strands with preloaded data" do
      subject = subject_fixture()
      year = year_fixture()
      strand = strand_fixture(%{subjects_ids: [subject.id], years_ids: [year.id]})

      [expected] = LearningContext.list_strands(preloads: [:subjects, :years])
      assert expected.id == strand.id
      assert expected.subjects == [subject]
      assert expected.years == [year]
    end

    test "get_strand!/2 returns the strand with given id" do
      strand = strand_fixture()
      assert LearningContext.get_strand!(strand.id) == strand
    end

    test "get_strand!/2 with preloads returns the strand with given id and preloaded data" do
      subject = subject_fixture()
      year = year_fixture()
      strand = strand_fixture(%{subjects_ids: [subject.id], years_ids: [year.id]})

      expected = LearningContext.get_strand!(strand.id, preloads: [:subjects, :years])
      assert expected.id == strand.id
      assert expected.subjects == [subject]
      assert expected.years == [year]
    end

    test "create_strand/1 with valid data creates a strand" do
      curriculum_item_1 = curriculum_item_fixture()
      curriculum_item_2 = curriculum_item_fixture()
      subject = subject_fixture()
      year = year_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        curriculum_items: [
          %{curriculum_item_id: curriculum_item_1.id},
          %{curriculum_item_id: curriculum_item_2.id}
        ],
        subjects_ids: [subject.id],
        years_ids: [year.id]
      }

      assert {:ok, %Strand{} = strand} = LearningContext.create_strand(valid_attrs)
      assert strand.name == "some name"
      assert strand.description == "some description"
      assert strand.subjects == [subject]
      assert strand.years == [year]

      [expected_strand_curriculum_item_1, expected_strand_curriculum_item_2] =
        strand.curriculum_items

      assert expected_strand_curriculum_item_1.curriculum_item_id == curriculum_item_1.id
      assert expected_strand_curriculum_item_1.position == 0
      assert expected_strand_curriculum_item_2.curriculum_item_id == curriculum_item_2.id
      assert expected_strand_curriculum_item_2.position == 1
    end

    test "create_strand/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LearningContext.create_strand(@invalid_attrs)
    end

    test "update_strand/2 with valid data updates the strand" do
      subject = subject_fixture()
      year_1 = year_fixture()
      year_2 = year_fixture()

      # subject is irrevelant, should be replaced
      # year is revelant, we'll keep it after update
      strand =
        strand_fixture(%{
          subjects_ids: [subject_fixture().id],
          years_ids: [year_1.id]
        })

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        subjects_ids: [subject.id],
        years_ids: [year_1.id, year_2.id]
      }

      assert {:ok, %Strand{} = strand} = LearningContext.update_strand(strand, update_attrs)
      assert strand.name == "some updated name"
      assert strand.description == "some updated description"
      assert strand.subjects == [subject]
      assert strand.years == [year_1, year_2] || strand.years == [year_2, year_1]
    end

    test "update_strand/2 with curriculum items works as expected" do
      curriculum_item_1 = curriculum_item_fixture()
      curriculum_item_2 = curriculum_item_fixture()
      curriculum_item_3 = curriculum_item_fixture()

      # strand starts with [ci_1, ci_2]
      # and updates to [ci_3, ci_1]
      strand =
        strand_fixture(%{
          curriculum_items: [
            %{curriculum_item_id: curriculum_item_1.id},
            %{curriculum_item_id: curriculum_item_2.id}
          ]
        })

      update_attrs = %{
        curriculum_items: [
          %{curriculum_item_id: curriculum_item_3.id},
          %{curriculum_item_id: curriculum_item_1.id}
        ]
      }

      assert {:ok, %Strand{} = strand} = LearningContext.update_strand(strand, update_attrs)

      [expected_ci_3, expected_ci_1] =
        strand.curriculum_items

      assert expected_ci_3.curriculum_item_id == curriculum_item_3.id
      assert expected_ci_3.position == 0
      assert expected_ci_1.curriculum_item_id == curriculum_item_1.id
      assert expected_ci_1.position == 1
    end

    test "update_strand/2 with invalid data returns error changeset" do
      strand = strand_fixture()
      assert {:error, %Ecto.Changeset{}} = LearningContext.update_strand(strand, @invalid_attrs)
      assert strand == LearningContext.get_strand!(strand.id)
    end

    test "delete_strand/1 deletes the strand" do
      strand = strand_fixture()
      assert {:ok, %Strand{}} = LearningContext.delete_strand(strand)
      assert_raise Ecto.NoResultsError, fn -> LearningContext.get_strand!(strand.id) end
    end

    test "change_strand/1 returns a strand changeset" do
      strand = strand_fixture()
      assert %Ecto.Changeset{} = LearningContext.change_strand(strand)
    end
  end

  describe "activities" do
    alias Lanttern.LearningContext.Activity

    import Lanttern.TaxonomyFixtures
    import Lanttern.CurriculaFixtures

    @invalid_attrs %{name: nil, position: nil, description: nil}

    test "list_activities/1 returns all activities" do
      activity = activity_fixture()
      assert LearningContext.list_activities() == [activity]
    end

    test "list_activities/1 with preloads returns all activities with preloaded data" do
      strand = strand_fixture()
      subject = subject_fixture()
      activity = activity_fixture(%{strand_id: strand.id, subjects_ids: [subject.id]})

      [expected] = LearningContext.list_activities(preloads: [:subjects, :strand])
      assert expected.id == activity.id
      assert expected.strand == strand
      assert expected.subjects == [subject]
    end

    test "list_activities/1 with strands filter returns activities filtered" do
      strand = strand_fixture()
      subject = subject_fixture()
      activity = activity_fixture(%{strand_id: strand.id, subjects_ids: [subject.id]})

      # extra activities for filter testing
      activity_fixture()
      activity_fixture()

      [expected] = LearningContext.list_activities(strands_ids: [strand.id], preloads: :subjects)
      assert expected.id == activity.id
      assert expected.subjects == [subject]
    end

    test "get_activity!/2 returns the activity with given id" do
      activity = activity_fixture()
      assert LearningContext.get_activity!(activity.id) == activity
    end

    test "get_activity!/2 with preloads returns the activity with given id and preloaded data" do
      strand = strand_fixture()
      subject = subject_fixture()
      activity = activity_fixture(%{strand_id: strand.id, subjects_ids: [subject.id]})

      expected = LearningContext.get_activity!(activity.id, preloads: [:strand, :subjects])
      assert expected.id == activity.id
      assert expected.strand == strand
      assert expected.subjects == [subject]
    end

    test "create_activity/1 with valid data creates a activity" do
      subject = subject_fixture()

      valid_attrs = %{
        name: "some name",
        position: 42,
        description: "some description",
        strand_id: strand_fixture().id,
        subjects_ids: [subject.id]
      }

      assert {:ok, %Activity{} = activity} = LearningContext.create_activity(valid_attrs)
      assert activity.name == "some name"
      assert activity.position == 42
      assert activity.description == "some description"
      assert activity.subjects == [subject]
    end

    test "create_activity/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LearningContext.create_activity(@invalid_attrs)
    end

    test "update_activity/2 with valid data updates the activity" do
      activity = activity_fixture(%{subjects_ids: [subject_fixture().id]})
      subject = subject_fixture()

      update_attrs = %{
        name: "some updated name",
        position: 43,
        description: "some updated description",
        subjects_ids: [subject.id]
      }

      assert {:ok, %Activity{} = activity} =
               LearningContext.update_activity(activity, update_attrs)

      assert activity.name == "some updated name"
      assert activity.position == 43
      assert activity.description == "some updated description"
      assert activity.subjects == [subject]
    end

    test "update_activity/2 with invalid data returns error changeset" do
      activity = activity_fixture()

      assert {:error, %Ecto.Changeset{}} =
               LearningContext.update_activity(activity, @invalid_attrs)

      assert activity == LearningContext.get_activity!(activity.id)
    end

    test "update_strand_activities_positions/2 update strand activities position based on list order" do
      strand = strand_fixture()
      activity_1 = activity_fixture(%{strand_id: strand.id})
      activity_2 = activity_fixture(%{strand_id: strand.id})
      activity_3 = activity_fixture(%{strand_id: strand.id})
      activity_4 = activity_fixture(%{strand_id: strand.id})

      sorted_activities_ids =
        [
          activity_2.id,
          activity_3.id,
          activity_1.id,
          activity_4.id
        ]

      assert {:ok,
              [
                expected_2,
                expected_3,
                expected_1,
                expected_4
              ]} =
               LearningContext.update_strand_activities_positions(
                 strand.id,
                 sorted_activities_ids
               )

      assert expected_1.id == activity_1.id
      assert expected_2.id == activity_2.id
      assert expected_3.id == activity_3.id
      assert expected_4.id == activity_4.id
    end

    test "delete_activity/1 deletes the activity" do
      activity = activity_fixture()
      assert {:ok, %Activity{}} = LearningContext.delete_activity(activity)
      assert_raise Ecto.NoResultsError, fn -> LearningContext.get_activity!(activity.id) end
    end

    test "change_activity/1 returns a activity changeset" do
      activity = activity_fixture()
      assert %Ecto.Changeset{} = LearningContext.change_activity(activity)
    end
  end
end
