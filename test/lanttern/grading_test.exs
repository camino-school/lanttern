defmodule Lanttern.GradingTest do
  use Lanttern.DataCase

  alias Lanttern.Grading

  describe "compositions" do
    alias Lanttern.Grading.Composition

    import Lanttern.GradingFixtures

    @invalid_attrs %{name: nil}

    test "list_compositions/0 returns all compositions" do
      composition = composition_fixture()
      assert Grading.list_compositions() == [composition]
    end

    test "get_composition!/1 returns the composition with given id" do
      composition = composition_fixture()
      assert Grading.get_composition!(composition.id) == composition
    end

    test "create_composition/1 with valid data creates a composition" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Composition{} = composition} = Grading.create_composition(valid_attrs)
      assert composition.name == "some name"
    end

    test "create_composition/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_composition(@invalid_attrs)
    end

    test "update_composition/2 with valid data updates the composition" do
      composition = composition_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Composition{} = composition} =
               Grading.update_composition(composition, update_attrs)

      assert composition.name == "some updated name"
    end

    test "update_composition/2 with invalid data returns error changeset" do
      composition = composition_fixture()
      assert {:error, %Ecto.Changeset{}} = Grading.update_composition(composition, @invalid_attrs)
      assert composition == Grading.get_composition!(composition.id)
    end

    test "delete_composition/1 deletes the composition" do
      composition = composition_fixture()
      assert {:ok, %Composition{}} = Grading.delete_composition(composition)
      assert_raise Ecto.NoResultsError, fn -> Grading.get_composition!(composition.id) end
    end

    test "change_composition/1 returns a composition changeset" do
      composition = composition_fixture()
      assert %Ecto.Changeset{} = Grading.change_composition(composition)
    end
  end

  describe "composition_components" do
    alias Lanttern.Grading.CompositionComponent

    import Lanttern.GradingFixtures

    @invalid_attrs %{name: nil, weight: nil}

    test "list_composition_components/0 returns all composition_components" do
      composition_component = composition_component_fixture()
      assert Grading.list_composition_components() == [composition_component]
    end

    test "get_composition_component!/1 returns the composition_component with given id" do
      composition_component = composition_component_fixture()
      assert Grading.get_composition_component!(composition_component.id) == composition_component
    end

    test "create_composition_component/1 with valid data creates a composition_component" do
      composition = composition_fixture()
      valid_attrs = %{name: "some name", weight: 120.5, composition_id: composition.id}

      assert {:ok, %CompositionComponent{} = composition_component} =
               Grading.create_composition_component(valid_attrs)

      assert composition_component.name == "some name"
      assert composition_component.weight == 120.5
      assert composition_component.composition_id == composition.id
    end

    test "create_composition_component/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_composition_component(@invalid_attrs)
    end

    test "update_composition_component/2 with valid data updates the composition_component" do
      composition_component = composition_component_fixture()
      update_attrs = %{name: "some updated name", weight: 456.7}

      assert {:ok, %CompositionComponent{} = composition_component} =
               Grading.update_composition_component(composition_component, update_attrs)

      assert composition_component.name == "some updated name"
      assert composition_component.weight == 456.7
    end

    test "update_composition_component/2 with invalid data returns error changeset" do
      composition_component = composition_component_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Grading.update_composition_component(composition_component, @invalid_attrs)

      assert composition_component == Grading.get_composition_component!(composition_component.id)
    end

    test "delete_composition_component/1 deletes the composition_component" do
      composition_component = composition_component_fixture()

      assert {:ok, %CompositionComponent{}} =
               Grading.delete_composition_component(composition_component)

      assert_raise Ecto.NoResultsError, fn ->
        Grading.get_composition_component!(composition_component.id)
      end
    end

    test "change_composition_component/1 returns a composition_component changeset" do
      composition_component = composition_component_fixture()
      assert %Ecto.Changeset{} = Grading.change_composition_component(composition_component)
    end
  end

  describe "component_items" do
    alias Lanttern.Grading.CompositionComponentItem

    import Lanttern.GradingFixtures
    alias Lanttern.CurriculaFixtures

    @invalid_attrs %{weight: nil}

    test "list_component_items/0 returns all component_items" do
      composition_component_item = composition_component_item_fixture()
      assert Grading.list_component_items() == [composition_component_item]
    end

    test "get_composition_component_item!/1 returns the composition_component_item with given id" do
      composition_component_item = composition_component_item_fixture()

      assert Grading.get_composition_component_item!(composition_component_item.id) ==
               composition_component_item
    end

    test "create_composition_component_item/1 with valid data creates a composition_component_item" do
      component = composition_component_fixture()
      curriculum_item = CurriculaFixtures.item_fixture()

      valid_attrs = %{
        weight: 120.5,
        component_id: component.id,
        curriculum_item_id: curriculum_item.id
      }

      assert {:ok, %CompositionComponentItem{} = composition_component_item} =
               Grading.create_composition_component_item(valid_attrs)

      assert composition_component_item.weight == 120.5
      assert composition_component_item.component_id == component.id
      assert composition_component_item.curriculum_item_id == curriculum_item.id
    end

    test "create_composition_component_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Grading.create_composition_component_item(@invalid_attrs)
    end

    test "update_composition_component_item/2 with valid data updates the composition_component_item" do
      composition_component_item = composition_component_item_fixture()
      update_attrs = %{weight: 456.7}

      assert {:ok, %CompositionComponentItem{} = composition_component_item} =
               Grading.update_composition_component_item(composition_component_item, update_attrs)

      assert composition_component_item.weight == 456.7
    end

    test "update_composition_component_item/2 with invalid data returns error changeset" do
      composition_component_item = composition_component_item_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Grading.update_composition_component_item(
                 composition_component_item,
                 @invalid_attrs
               )

      assert composition_component_item ==
               Grading.get_composition_component_item!(composition_component_item.id)
    end

    test "delete_composition_component_item/1 deletes the composition_component_item" do
      composition_component_item = composition_component_item_fixture()

      assert {:ok, %CompositionComponentItem{}} =
               Grading.delete_composition_component_item(composition_component_item)

      assert_raise Ecto.NoResultsError, fn ->
        Grading.get_composition_component_item!(composition_component_item.id)
      end
    end

    test "change_composition_component_item/1 returns a composition_component_item changeset" do
      composition_component_item = composition_component_item_fixture()

      assert %Ecto.Changeset{} =
               Grading.change_composition_component_item(composition_component_item)
    end
  end
end
