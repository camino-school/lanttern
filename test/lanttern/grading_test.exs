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

  describe "numeric_scales" do
    alias Lanttern.Grading.NumericScale

    import Lanttern.GradingFixtures

    @invalid_attrs %{name: nil, start: nil, stop: nil}

    test "list_numeric_scales/0 returns all numeric_scales" do
      numeric_scale = numeric_scale_fixture()
      assert Grading.list_numeric_scales() == [numeric_scale]
    end

    test "get_numeric_scale!/1 returns the numeric_scale with given id" do
      numeric_scale = numeric_scale_fixture()
      assert Grading.get_numeric_scale!(numeric_scale.id) == numeric_scale
    end

    test "create_numeric_scale/1 with valid data creates a numeric_scale" do
      valid_attrs = %{name: "some name", start: 120.5, stop: 120.5}

      assert {:ok, %NumericScale{} = numeric_scale} = Grading.create_numeric_scale(valid_attrs)
      assert numeric_scale.name == "some name"
      assert numeric_scale.start == 120.5
      assert numeric_scale.stop == 120.5
    end

    test "create_numeric_scale/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_numeric_scale(@invalid_attrs)
    end

    test "update_numeric_scale/2 with valid data updates the numeric_scale" do
      numeric_scale = numeric_scale_fixture()
      update_attrs = %{name: "some updated name", start: 456.7, stop: 456.7}

      assert {:ok, %NumericScale{} = numeric_scale} =
               Grading.update_numeric_scale(numeric_scale, update_attrs)

      assert numeric_scale.name == "some updated name"
      assert numeric_scale.start == 456.7
      assert numeric_scale.stop == 456.7
    end

    test "update_numeric_scale/2 with invalid data returns error changeset" do
      numeric_scale = numeric_scale_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Grading.update_numeric_scale(numeric_scale, @invalid_attrs)

      assert numeric_scale == Grading.get_numeric_scale!(numeric_scale.id)
    end

    test "delete_numeric_scale/1 deletes the numeric_scale" do
      numeric_scale = numeric_scale_fixture()
      assert {:ok, %NumericScale{}} = Grading.delete_numeric_scale(numeric_scale)
      assert_raise Ecto.NoResultsError, fn -> Grading.get_numeric_scale!(numeric_scale.id) end
    end

    test "change_numeric_scale/1 returns a numeric_scale changeset" do
      numeric_scale = numeric_scale_fixture()
      assert %Ecto.Changeset{} = Grading.change_numeric_scale(numeric_scale)
    end
  end

  describe "ordinal_scales" do
    alias Lanttern.Grading.OrdinalScale

    import Lanttern.GradingFixtures

    @invalid_attrs %{name: nil}

    test "list_ordinal_scales/0 returns all ordinal_scales" do
      ordinal_scale = ordinal_scale_fixture()
      assert Grading.list_ordinal_scales() == [ordinal_scale]
    end

    test "get_ordinal_scale!/1 returns the ordinal_scale with given id" do
      ordinal_scale = ordinal_scale_fixture()
      assert Grading.get_ordinal_scale!(ordinal_scale.id) == ordinal_scale
    end

    test "create_ordinal_scale/1 with valid data creates a ordinal_scale" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %OrdinalScale{} = ordinal_scale} = Grading.create_ordinal_scale(valid_attrs)
      assert ordinal_scale.name == "some name"
    end

    test "create_ordinal_scale/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_ordinal_scale(@invalid_attrs)
    end

    test "update_ordinal_scale/2 with valid data updates the ordinal_scale" do
      ordinal_scale = ordinal_scale_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %OrdinalScale{} = ordinal_scale} =
               Grading.update_ordinal_scale(ordinal_scale, update_attrs)

      assert ordinal_scale.name == "some updated name"
    end

    test "update_ordinal_scale/2 with invalid data returns error changeset" do
      ordinal_scale = ordinal_scale_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Grading.update_ordinal_scale(ordinal_scale, @invalid_attrs)

      assert ordinal_scale == Grading.get_ordinal_scale!(ordinal_scale.id)
    end

    test "delete_ordinal_scale/1 deletes the ordinal_scale" do
      ordinal_scale = ordinal_scale_fixture()
      assert {:ok, %OrdinalScale{}} = Grading.delete_ordinal_scale(ordinal_scale)
      assert_raise Ecto.NoResultsError, fn -> Grading.get_ordinal_scale!(ordinal_scale.id) end
    end

    test "change_ordinal_scale/1 returns a ordinal_scale changeset" do
      ordinal_scale = ordinal_scale_fixture()
      assert %Ecto.Changeset{} = Grading.change_ordinal_scale(ordinal_scale)
    end
  end

  describe "ordinal_values" do
    alias Lanttern.Grading.OrdinalValue

    import Lanttern.GradingFixtures

    @invalid_attrs %{name: nil, order: nil}

    test "list_ordinal_values/0 returns all ordinal_values" do
      ordinal_value = ordinal_value_fixture()
      assert Grading.list_ordinal_values() == [ordinal_value]
    end

    test "get_ordinal_value!/1 returns the ordinal_value with given id" do
      ordinal_value = ordinal_value_fixture()
      assert Grading.get_ordinal_value!(ordinal_value.id) == ordinal_value
    end

    test "create_ordinal_value/1 with valid data creates a ordinal_value" do
      scale = ordinal_scale_fixture()
      valid_attrs = %{name: "some name", order: 42, scale_id: scale.id}

      assert {:ok, %OrdinalValue{} = ordinal_value} = Grading.create_ordinal_value(valid_attrs)
      assert ordinal_value.name == "some name"
      assert ordinal_value.order == 42
      assert ordinal_value.scale_id == scale.id
    end

    test "create_ordinal_value/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_ordinal_value(@invalid_attrs)
    end

    test "update_ordinal_value/2 with valid data updates the ordinal_value" do
      ordinal_value = ordinal_value_fixture()
      update_attrs = %{name: "some updated name", order: 43}

      assert {:ok, %OrdinalValue{} = ordinal_value} =
               Grading.update_ordinal_value(ordinal_value, update_attrs)

      assert ordinal_value.name == "some updated name"
      assert ordinal_value.order == 43
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

  describe "scales" do
    alias Lanttern.Grading.Scale

    import Lanttern.GradingFixtures

    @invalid_attrs %{name: nil, start: nil, stop: nil, type: nil}

    @invalid_numeric_attrs %{name: "0 to 10", start: nil, stop: nil, type: "numeric"}

    test "list_scales/0 returns all scales" do
      scale = scale_fixture()
      assert Grading.list_scales() == [scale]
    end

    test "get_scale!/1 returns the scale with given id" do
      scale = scale_fixture()
      assert Grading.get_scale!(scale.id) == scale
    end

    test "create_scale/1 with valid data creates a scale" do
      valid_attrs = %{name: "some name", start: 120.5, stop: 120.5, type: "some type"}

      assert {:ok, %Scale{} = scale} = Grading.create_scale(valid_attrs)
      assert scale.name == "some name"
      assert scale.start == 120.5
      assert scale.stop == 120.5
      assert scale.type == "some type"
    end

    test "create_scale/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_scale(@invalid_attrs)
    end

    test "create_scale/1 of type numeric without start and stop returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_scale(@invalid_numeric_attrs)
    end

    test "update_scale/2 with valid data updates the scale" do
      scale = scale_fixture()

      update_attrs = %{
        name: "some updated name",
        start: 456.7,
        stop: 456.7,
        type: "some updated type"
      }

      assert {:ok, %Scale{} = scale} = Grading.update_scale(scale, update_attrs)
      assert scale.name == "some updated name"
      assert scale.start == 456.7
      assert scale.stop == 456.7
      assert scale.type == "some updated type"
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
end
