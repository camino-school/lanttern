defmodule Lanttern.RubricsTest do
  use Lanttern.DataCase

  alias Lanttern.Rubrics
  alias Lanttern.GradingFixtures
  import Lanttern.RubricsFixtures

  describe "rubrics" do
    alias Lanttern.Rubrics.Rubric

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
        scale_id: GradingFixtures.scale_fixture().id,
        is_differentiation: true
      }

      assert {:ok, %Rubric{} = rubric} = Rubrics.create_rubric(valid_attrs)
      assert rubric.criteria == "some criteria"
      assert rubric.is_differentiation == true
    end

    test "create_rubric/1 with valid data including descriptors creates a rubric and related descriptors" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ordinal_value = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})

      valid_attrs = %{
        criteria: "some criteria with descriptors",
        scale_id: scale.id,
        is_differentiation: true,
        descriptors: [
          %{
            scale_id: scale.id,
            scale_type: scale.type,
            ordinal_value_id: ordinal_value.id,
            descriptor: "some descriptor in rubric"
          }
        ]
      }

      assert {:ok, %Rubric{} = rubric} = Rubrics.create_rubric(valid_attrs)
      assert rubric.criteria == "some criteria with descriptors"
      assert rubric.is_differentiation == true

      [expected_descriptor] = rubric.descriptors
      assert expected_descriptor.descriptor == "some descriptor in rubric"
      assert expected_descriptor.ordinal_value_id == ordinal_value.id
    end

    test "create_rubric/1 with valid data and preloads opt creates a rubric and return it with preloaded data" do
      scale = GradingFixtures.scale_fixture()

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

    test "update_rubric/2 with valid data including descriptors updates the rubric and handle descriptors correctly" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})

      ordinal_value_1 =
        GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0})

      ordinal_value_2 =
        GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.5})

      ordinal_value_3 =
        GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 1})

      rubric = rubric_fixture(%{scale_id: scale.id})

      descriptor =
        rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ordinal_value_1.id
        })

      descriptor_to_remove =
        rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ordinal_value_2.id
        })

      rubric = rubric |> Lanttern.Repo.preload(:descriptors)

      update_attrs = %{
        criteria: "some updated criteria",
        descriptors: [
          %{
            id: descriptor.id,
            rubric_id: rubric.id,
            scale_id: scale.id,
            scale_type: scale.type,
            ordinal_value_id: ordinal_value_1.id,
            descriptor: "updated descriptor 1"
          },
          %{
            rubric_id: rubric.id,
            scale_id: scale.id,
            scale_type: scale.type,
            ordinal_value_id: ordinal_value_3.id,
            descriptor: "new descriptor 3"
          }
        ]
      }

      assert {:ok, %Rubric{} = rubric} = Rubrics.update_rubric(rubric, update_attrs)

      assert rubric.criteria == "some updated criteria"
      assert length(rubric.descriptors) == 2
      existing_descriptor = rubric.descriptors |> Enum.find(&(&1.id == descriptor.id))
      assert existing_descriptor.descriptor == "updated descriptor 1"
      refute rubric.descriptors |> Enum.find(&(&1.id == descriptor_to_remove.id))
      assert rubric.descriptors |> Enum.find(&(&1.descriptor == "new descriptor 3"))
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
      scale = GradingFixtures.scale_fixture(%{type: "numeric"})
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
