defmodule Lanttern.LearningContextTest do
  use Lanttern.DataCase

  alias Lanttern.LearningContext

  describe "strands" do
    alias Lanttern.LearningContext.Strand

    import Lanttern.LearningContextFixtures
    import Lanttern.TaxonomyFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_strands/1 returns all strands" do
      strand = strand_fixture()
      assert LearningContext.list_strands() == [strand]
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
      subject = subject_fixture()
      year = year_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        subjects_ids: [subject.id],
        years_ids: [year.id]
      }

      assert {:ok, %Strand{} = strand} = LearningContext.create_strand(valid_attrs)
      assert strand.name == "some name"
      assert strand.description == "some description"
      assert strand.subjects == [subject]
      assert strand.years == [year]
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
end
