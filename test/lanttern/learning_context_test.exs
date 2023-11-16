defmodule Lanttern.LearningContextTest do
  use Lanttern.DataCase

  alias Lanttern.LearningContext

  describe "strands" do
    alias Lanttern.LearningContext.Strand

    import Lanttern.LearningContextFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_strands/0 returns all strands" do
      strand = strand_fixture()
      assert LearningContext.list_strands() == [strand]
    end

    test "get_strand!/1 returns the strand with given id" do
      strand = strand_fixture()
      assert LearningContext.get_strand!(strand.id) == strand
    end

    test "create_strand/1 with valid data creates a strand" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %Strand{} = strand} = LearningContext.create_strand(valid_attrs)
      assert strand.name == "some name"
      assert strand.description == "some description"
    end

    test "create_strand/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LearningContext.create_strand(@invalid_attrs)
    end

    test "update_strand/2 with valid data updates the strand" do
      strand = strand_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Strand{} = strand} = LearningContext.update_strand(strand, update_attrs)
      assert strand.name == "some updated name"
      assert strand.description == "some updated description"
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
