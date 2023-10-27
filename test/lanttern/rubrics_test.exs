defmodule Lanttern.RubricsTest do
  use Lanttern.DataCase

  alias Lanttern.Rubrics

  describe "rubrics" do
    alias Lanttern.Rubrics.Rubric

    import Lanttern.RubricsFixtures
    alias Lanttern.GradingFixtures

    @invalid_attrs %{criteria: nil, is_differentiation: nil}

    test "list_rubrics/1 returns all rubrics" do
      rubric = rubric_fixture()
      assert Rubrics.list_rubrics() == [rubric]
    end

    test "list_rubrics/1 with preloads returns all rubrics with preloaded data" do
      scale = GradingFixtures.scale_fixture()

      rubric = rubric_fixture(%{scale_id: scale.id})

      [expected] = Rubrics.list_rubrics(preloads: :scale)
      assert expected.id == rubric.id
      assert expected.scale.id == scale.id
    end

    test "get_rubric!/2 returns the rubric with given id" do
      rubric = rubric_fixture()
      assert Rubrics.get_rubric!(rubric.id) == rubric
    end

    test "get_rubric!/2 with preloads returns the rubric with given id and preloaded data" do
      scale = GradingFixtures.scale_fixture()

      rubric = rubric_fixture(%{scale_id: scale.id})

      expected =
        Rubrics.get_rubric!(rubric.id, preloads: :scale)

      assert expected.id == rubric.id
      assert expected.scale.id == scale.id
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

    test "create_rubric/1 with valid data and preloads opt creates a rubric and return it with preloaded data" do
      scale = Lanttern.GradingFixtures.scale_fixture()

      valid_attrs = %{
        criteria: "some criteria",
        scale_id: scale.id,
        is_differentiation: true
      }

      assert {:ok, %Rubric{} = rubric} = Rubrics.create_rubric(valid_attrs, preloads: :scale)
      assert rubric.criteria == "some criteria"
      assert rubric.scale.id == scale.id
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

    test "update_rubric/2 with valid data and preloads opt updates the rubric and return it with preloaded data" do
      rubric = rubric_fixture()
      scale = GradingFixtures.scale_fixture()

      update_attrs = %{
        criteria: "some updated criteria",
        scale_id: scale.id,
        is_differentiation: false
      }

      assert {:ok, %Rubric{} = rubric} =
               Rubrics.update_rubric(rubric, update_attrs, preloads: :scale)

      assert rubric.criteria == "some updated criteria"
      assert rubric.scale.id == scale.id
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

  describe "rubric_descriptors" do
    alias Lanttern.Rubrics.RubricDescriptor

    import Lanttern.RubricsFixtures

    @invalid_attrs %{descriptor: nil, score: nil}

    test "list_rubric_descriptors/0 returns all rubric_descriptors" do
      rubric_descriptor = rubric_descriptor_fixture()
      assert Rubrics.list_rubric_descriptors() == [rubric_descriptor]
    end

    test "get_rubric_descriptor!/1 returns the rubric_descriptor with given id" do
      rubric_descriptor = rubric_descriptor_fixture()
      assert Rubrics.get_rubric_descriptor!(rubric_descriptor.id) == rubric_descriptor
    end

    test "create_rubric_descriptor/1 with valid data creates a rubric_descriptor" do
      scale = Lanttern.GradingFixtures.scale_fixture(%{type: "numeric"})
      rubric = rubric_fixture(%{scale_id: scale.id})

      valid_attrs = %{
        descriptor: "some descriptor",
        rubric_id: rubric.id,
        scale_id: scale.id,
        scale_type: scale.type,
        score: 120.5
      }

      assert {:ok, %RubricDescriptor{} = rubric_descriptor} =
               Rubrics.create_rubric_descriptor(valid_attrs)

      assert rubric_descriptor.descriptor == "some descriptor"
      assert rubric_descriptor.score == 120.5
    end

    test "create_rubric_descriptor/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rubrics.create_rubric_descriptor(@invalid_attrs)
    end

    test "update_rubric_descriptor/2 with valid data updates the rubric_descriptor" do
      rubric_descriptor = rubric_descriptor_fixture()
      update_attrs = %{descriptor: "some updated descriptor"}

      assert {:ok, %RubricDescriptor{} = rubric_descriptor} =
               Rubrics.update_rubric_descriptor(rubric_descriptor, update_attrs)

      assert rubric_descriptor.descriptor == "some updated descriptor"
    end

    test "update_rubric_descriptor/2 with invalid data returns error changeset" do
      rubric_descriptor = rubric_descriptor_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Rubrics.update_rubric_descriptor(rubric_descriptor, @invalid_attrs)

      assert rubric_descriptor == Rubrics.get_rubric_descriptor!(rubric_descriptor.id)
    end

    test "delete_rubric_descriptor/1 deletes the rubric_descriptor" do
      rubric_descriptor = rubric_descriptor_fixture()
      assert {:ok, %RubricDescriptor{}} = Rubrics.delete_rubric_descriptor(rubric_descriptor)

      assert_raise Ecto.NoResultsError, fn ->
        Rubrics.get_rubric_descriptor!(rubric_descriptor.id)
      end
    end

    test "change_rubric_descriptor/1 returns a rubric_descriptor changeset" do
      rubric_descriptor = rubric_descriptor_fixture()
      assert %Ecto.Changeset{} = Rubrics.change_rubric_descriptor(rubric_descriptor)
    end
  end
end
