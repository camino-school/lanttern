defmodule Lanttern.RubricsTest do
  use Lanttern.DataCase

  alias Lanttern.Rubrics

  describe "rubrics" do
    alias Lanttern.Rubrics.Rubric

    import Lanttern.RubricsFixtures

    @invalid_attrs %{criteria: nil, is_differentiation: nil}

    test "list_rubrics/0 returns all rubrics" do
      rubric = rubric_fixture()
      assert Rubrics.list_rubrics() == [rubric]
    end

    test "get_rubric!/1 returns the rubric with given id" do
      rubric = rubric_fixture()
      assert Rubrics.get_rubric!(rubric.id) == rubric
    end

    test "create_rubric/1 with valid data creates a rubric" do
      valid_attrs = %{
        criteria: "some criteria",
        scale_id: Lanttern.GradingFixtures.scale_fixture().id,
        is_differentiation: true
      }

      assert {:ok, %Rubric{} = rubric} = Rubrics.create_rubric(valid_attrs)
      assert rubric.criteria == "some criteria"
      assert rubric.is_differentiation == true
    end

    test "create_rubric/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rubrics.create_rubric(@invalid_attrs)
    end

    test "update_rubric/2 with valid data updates the rubric" do
      rubric = rubric_fixture()
      update_attrs = %{criteria: "some updated criteria", is_differentiation: false}

      assert {:ok, %Rubric{} = rubric} = Rubrics.update_rubric(rubric, update_attrs)
      assert rubric.criteria == "some updated criteria"
      assert rubric.is_differentiation == false
    end

    test "update_rubric/2 with invalid data returns error changeset" do
      rubric = rubric_fixture()
      assert {:error, %Ecto.Changeset{}} = Rubrics.update_rubric(rubric, @invalid_attrs)
      assert rubric == Rubrics.get_rubric!(rubric.id)
    end

    test "delete_rubric/1 deletes the rubric" do
      rubric = rubric_fixture()
      assert {:ok, %Rubric{}} = Rubrics.delete_rubric(rubric)
      assert_raise Ecto.NoResultsError, fn -> Rubrics.get_rubric!(rubric.id) end
    end

    test "change_rubric/1 returns a rubric changeset" do
      rubric = rubric_fixture()
      assert %Ecto.Changeset{} = Rubrics.change_rubric(rubric)
    end
  end
end
