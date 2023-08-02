defmodule Lanttern.GradingTest do
  use Lanttern.DataCase

  alias Lanttern.Grading

  describe "compositions" do
    alias Lanttern.Grading.Composition

    import Lanttern.GradingFixtures

    @invalid_attrs %{name: nil}

    test "list_compositions/1 returns all compositions" do
      composition = composition_fixture()
      assert Grading.list_compositions() == [composition]
    end

    test "list_compositions/1 with prealoads returns all compositions with preloaded data" do
      scale = scale_fixture()

      composition =
        composition_fixture(%{final_grade_scale_id: scale.id})
        |> Map.put(:final_grade_scale, scale)

      assert Grading.list_compositions(:final_grade_scale) == [composition]
    end

    test "get_composition!/2 returns the composition with given id" do
      composition = composition_fixture()
      assert Grading.get_composition!(composition.id) == composition
    end

    test "get_composition!/2 with preloads returns the composition with given id and preloaded data" do
      scale = scale_fixture()

      composition =
        composition_fixture(%{final_grade_scale_id: scale.id})
        |> Map.put(:final_grade_scale, scale)

      assert Grading.get_composition!(composition.id, :final_grade_scale) == composition
    end

    test "create_composition/1 with valid data creates a composition" do
      scale = scale_fixture()
      valid_attrs = %{name: "some name", final_grade_scale_id: scale.id}

      assert {:ok, %Composition{} = composition} = Grading.create_composition(valid_attrs)
      assert composition.name == "some name"
      assert composition.final_grade_scale_id == scale.id
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

    test "list_composition_components/1 returns all composition_components" do
      composition_component = composition_component_fixture()
      assert Grading.list_composition_components() == [composition_component]
    end

    test "list_composition_components/1 with preloads returns all composition_components with preloaded data" do
      composition = composition_fixture()

      composition_component =
        composition_component_fixture(%{composition_id: composition.id})
        |> Map.put(:composition, composition)

      assert Grading.list_composition_components(:composition) == [composition_component]
    end

    test "get_composition_component!/2 returns the composition_component with given id" do
      composition_component = composition_component_fixture()
      assert Grading.get_composition_component!(composition_component.id) == composition_component
    end

    test "get_composition_component!/2 with preloads returns the composition_component with given id and preloaded data" do
      composition = composition_fixture()

      composition_component =
        composition_component_fixture(%{composition_id: composition.id})
        |> Map.put(:composition, composition)

      assert Grading.get_composition_component!(composition_component.id, :composition) ==
               composition_component
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

    test "list_component_items/1 returns all component_items" do
      composition_component_item = composition_component_item_fixture()
      assert Grading.list_component_items() == [composition_component_item]
    end

    test "list_component_items/1 with preloads returns all component_items with preloaded data" do
      component = composition_component_fixture()
      curriculum_item = Lanttern.CurriculaFixtures.item_fixture()

      composition_component_item =
        composition_component_item_fixture(%{
          component_id: component.id,
          curriculum_item_id: curriculum_item.id
        })
        |> Map.put(:component, component)
        |> Map.put(:curriculum_item, curriculum_item)

      assert Grading.list_component_items([:component, :curriculum_item]) ==
               [composition_component_item]
    end

    test "get_composition_component_item!/2 returns the composition_component_item with given id" do
      composition_component_item = composition_component_item_fixture()

      assert Grading.get_composition_component_item!(composition_component_item.id) ==
               composition_component_item
    end

    test "get_composition_component_item!/2 with preloads returns the composition_component_item with given id and preloaded data" do
      component = composition_component_fixture()
      curriculum_item = Lanttern.CurriculaFixtures.item_fixture()

      composition_component_item =
        composition_component_item_fixture(%{
          component_id: component.id,
          curriculum_item_id: curriculum_item.id
        })
        |> Map.put(:component, component)
        |> Map.put(:curriculum_item, curriculum_item)

      assert Grading.get_composition_component_item!(
               composition_component_item.id,
               [:component, :curriculum_item]
             ) ==
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

  describe "scales" do
    alias Lanttern.Grading.Scale

    import Lanttern.GradingFixtures

    @invalid_attrs %{name: nil, start: nil, stop: nil, type: nil}

    @invalid_numeric_attrs %{name: "0 to 10", start: nil, stop: nil, type: "numeric"}

    @invalid_breakpoint_attrs %{
      name: "Letter grades",
      start: nil,
      stop: nil,
      type: "ordinal",
      breakpoints: [0.5, 1.5]
    }

    test "list_scales/0 returns all scales" do
      scale = scale_fixture()
      assert Grading.list_scales() == [scale]
    end

    test "get_scale!/1 returns the scale with given id" do
      scale = scale_fixture()
      assert Grading.get_scale!(scale.id) == scale
    end

    test "create_scale/1 with valid data creates a scale" do
      valid_attrs = %{
        name: "some name",
        start: 120.5,
        stop: 120.5,
        type: "numeric",
        breakpoints: [0.4, 0.8]
      }

      assert {:ok, %Scale{} = scale} = Grading.create_scale(valid_attrs)
      assert scale.name == "some name"
      assert scale.start == 120.5
      assert scale.stop == 120.5
      assert scale.type == "numeric"
      assert scale.breakpoints == [0.4, 0.8]
    end

    test "create_scale/1 orders and remove duplications of breakpoints" do
      valid_attrs = %{
        name: "some name",
        start: nil,
        stop: nil,
        type: "ordinal",
        breakpoints: [0.4, 0.8, 0.80, 0.6]
      }

      assert {:ok, %Scale{} = scale} = Grading.create_scale(valid_attrs)
      assert scale.name == "some name"
      assert scale.type == "ordinal"
      assert scale.breakpoints == [0.4, 0.6, 0.8]
    end

    test "create_scale/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_scale(@invalid_attrs)
    end

    test "create_scale/1 of type numeric without start and stop returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_scale(@invalid_numeric_attrs)
    end

    test "create_scale/1 of with invalid breakpoints returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_scale(@invalid_breakpoint_attrs)
    end

    test "update_scale/2 with valid data updates the scale" do
      scale = scale_fixture()

      update_attrs = %{
        name: "some updated name",
        start: 456.7,
        stop: 456.7,
        type: "numeric"
      }

      assert {:ok, %Scale{} = scale} = Grading.update_scale(scale, update_attrs)
      assert scale.name == "some updated name"
      assert scale.start == 456.7
      assert scale.stop == 456.7
      assert scale.type == "numeric"
    end

    test "update_scale/2 with invalid data returns error changeset" do
      scale = scale_fixture()
      assert {:error, %Ecto.Changeset{}} = Grading.update_scale(scale, @invalid_attrs)
      assert scale == Grading.get_scale!(scale.id)
    end

    test "delete_scale/1 deletes the scale" do
      scale = scale_fixture()
      assert {:ok, %Scale{}} = Grading.delete_scale(scale)
      assert_raise Ecto.NoResultsError, fn -> Grading.get_scale!(scale.id) end
    end

    test "change_scale/1 returns a scale changeset" do
      scale = scale_fixture()
      assert %Ecto.Changeset{} = Grading.change_scale(scale)
    end
  end

  describe "ordinal_values" do
    alias Lanttern.Grading.OrdinalValue

    import Lanttern.GradingFixtures

    @invalid_attrs %{name: nil, order: nil}

    test "list_ordinal_values/1 returns all ordinal_values" do
      ordinal_value = ordinal_value_fixture()
      assert Grading.list_ordinal_values() == [ordinal_value]
    end

    test "list_ordinal_values/1 with preloads returns all ordinal_values with preloaded data" do
      scale = scale_fixture()

      ordinal_value =
        ordinal_value_fixture(%{scale_id: scale.id})
        |> Map.put(:scale, scale)

      assert Grading.list_ordinal_values(:scale) == [ordinal_value]
    end

    test "get_ordinal_value!/2 returns the ordinal_value with given id" do
      ordinal_value = ordinal_value_fixture()
      assert Grading.get_ordinal_value!(ordinal_value.id) == ordinal_value
    end

    test "get_ordinal_value!/2 with preloads returns the ordinal_value with given id and preloaded data" do
      scale = scale_fixture()

      ordinal_value =
        ordinal_value_fixture(%{scale_id: scale.id})
        |> Map.put(:scale, scale)

      assert Grading.get_ordinal_value!(ordinal_value.id, :scale) == ordinal_value
    end

    test "create_ordinal_value/1 with valid data creates a ordinal_value" do
      scale = scale_fixture()
      valid_attrs = %{name: "some name", normalized_value: 0.5, scale_id: scale.id}

      assert {:ok, %OrdinalValue{} = ordinal_value} = Grading.create_ordinal_value(valid_attrs)
      assert ordinal_value.name == "some name"
      assert ordinal_value.normalized_value == 0.5
      assert ordinal_value.scale_id == scale.id
    end

    test "create_ordinal_value/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_ordinal_value(@invalid_attrs)
    end

    test "update_ordinal_value/2 with valid data updates the ordinal_value" do
      ordinal_value = ordinal_value_fixture()
      update_attrs = %{name: "some updated name", normalized_value: 0.43}

      assert {:ok, %OrdinalValue{} = ordinal_value} =
               Grading.update_ordinal_value(ordinal_value, update_attrs)

      assert ordinal_value.name == "some updated name"
      assert ordinal_value.normalized_value == 0.43
    end

    test "update_ordinal_value/2 with invalid data returns error changeset" do
      ordinal_value = ordinal_value_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Grading.update_ordinal_value(ordinal_value, @invalid_attrs)

      assert ordinal_value == Grading.get_ordinal_value!(ordinal_value.id)
    end

    test "delete_ordinal_value/1 deletes the ordinal_value" do
      ordinal_value = ordinal_value_fixture()
      assert {:ok, %OrdinalValue{}} = Grading.delete_ordinal_value(ordinal_value)
      assert_raise Ecto.NoResultsError, fn -> Grading.get_ordinal_value!(ordinal_value.id) end
    end

    test "change_ordinal_value/1 returns a ordinal_value changeset" do
      ordinal_value = ordinal_value_fixture()
      assert %Ecto.Changeset{} = Grading.change_ordinal_value(ordinal_value)
    end
  end
end
