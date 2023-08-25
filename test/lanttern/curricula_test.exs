defmodule Lanttern.CurriculaTest do
  use Lanttern.DataCase

  alias Lanttern.Curricula

  describe "curricula" do
    alias Lanttern.Curricula.Curriculum

    import Lanttern.CurriculaFixtures

    @invalid_attrs %{name: nil}

    test "list_curricula/0 returns all curricula" do
      curriculum = curriculum_fixture()
      assert Curricula.list_curricula() == [curriculum]
    end

    test "get_curriculum!/1 returns the curriculum with given id" do
      curriculum = curriculum_fixture()
      assert Curricula.get_curriculum!(curriculum.id) == curriculum
    end

    test "create_curriculum/1 with valid data creates a curriculum" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Curriculum{} = curriculum} = Curricula.create_curriculum(valid_attrs)
      assert curriculum.name == "some name"
    end

    test "create_curriculum/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Curricula.create_curriculum(@invalid_attrs)
    end

    test "update_curriculum/2 with valid data updates the curriculum" do
      curriculum = curriculum_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Curriculum{} = curriculum} =
               Curricula.update_curriculum(curriculum, update_attrs)

      assert curriculum.name == "some updated name"
    end

    test "update_curriculum/2 with invalid data returns error changeset" do
      curriculum = curriculum_fixture()
      assert {:error, %Ecto.Changeset{}} = Curricula.update_curriculum(curriculum, @invalid_attrs)
      assert curriculum == Curricula.get_curriculum!(curriculum.id)
    end

    test "delete_curriculum/1 deletes the curriculum" do
      curriculum = curriculum_fixture()
      assert {:ok, %Curriculum{}} = Curricula.delete_curriculum(curriculum)
      assert_raise Ecto.NoResultsError, fn -> Curricula.get_curriculum!(curriculum.id) end
    end

    test "change_curriculum/1 returns a curriculum changeset" do
      curriculum = curriculum_fixture()
      assert %Ecto.Changeset{} = Curricula.change_curriculum(curriculum)
    end
  end

  describe "curriculum_components" do
    alias Lanttern.Curricula.CurriculumComponent

    import Lanttern.CurriculaFixtures

    @invalid_attrs %{code: nil, name: nil}

    test "list_curriculum_components/1 returns all curriculum_components" do
      curriculum_component = curriculum_component_fixture()
      assert Curricula.list_curriculum_components() == [curriculum_component]
    end

    test "list_curriculum_components/1 with preloads returns all curriculum_components with preloaded data" do
      curriculum = curriculum_fixture()

      curriculum_component = curriculum_component_fixture(%{curriculum_id: curriculum.id})

      [expected] = Curricula.list_curriculum_components(preloads: :curriculum)
      assert expected.id == curriculum_component.id
      assert expected.curriculum == curriculum
    end

    test "get_curriculum_component!/2 returns the curriculum_component with given id" do
      curriculum_component = curriculum_component_fixture()
      assert Curricula.get_curriculum_component!(curriculum_component.id) == curriculum_component
    end

    test "get_curriculum_component!/2 with preloads returns the curriculum_component with given id and preloaded data" do
      curriculum = curriculum_fixture()

      curriculum_component = curriculum_component_fixture(%{curriculum_id: curriculum.id})

      expected =
        Curricula.get_curriculum_component!(curriculum_component.id, preloads: :curriculum)

      assert expected.id == curriculum_component.id
      assert expected.curriculum == curriculum
    end

    test "create_curriculum_component/1 with valid data creates a curriculum_component" do
      curriculum = curriculum_fixture()
      valid_attrs = %{code: "some code", name: "some name", curriculum_id: curriculum.id}

      assert {:ok, %CurriculumComponent{} = curriculum_component} =
               Curricula.create_curriculum_component(valid_attrs)

      assert curriculum_component.code == "some code"
      assert curriculum_component.name == "some name"
      assert curriculum_component.curriculum_id == curriculum.id
    end

    test "create_curriculum_component/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Curricula.create_curriculum_component(@invalid_attrs)
    end

    test "update_curriculum_component/2 with valid data updates the curriculum_component" do
      curriculum_component = curriculum_component_fixture()
      update_attrs = %{code: "some updated code", name: "some updated name"}

      assert {:ok, %CurriculumComponent{} = curriculum_component} =
               Curricula.update_curriculum_component(curriculum_component, update_attrs)

      assert curriculum_component.code == "some updated code"
      assert curriculum_component.name == "some updated name"
    end

    test "update_curriculum_component/2 with invalid data returns error changeset" do
      curriculum_component = curriculum_component_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Curricula.update_curriculum_component(curriculum_component, @invalid_attrs)

      assert curriculum_component == Curricula.get_curriculum_component!(curriculum_component.id)
    end

    test "delete_curriculum_component/1 deletes the curriculum_component" do
      curriculum_component = curriculum_component_fixture()

      assert {:ok, %CurriculumComponent{}} =
               Curricula.delete_curriculum_component(curriculum_component)

      assert_raise Ecto.NoResultsError, fn ->
        Curricula.get_curriculum_component!(curriculum_component.id)
      end
    end

    test "change_curriculum_component/1 returns a curriculum_component changeset" do
      curriculum_component = curriculum_component_fixture()
      assert %Ecto.Changeset{} = Curricula.change_curriculum_component(curriculum_component)
    end
  end

  describe "items" do
    alias Lanttern.Curricula.CurriculumItem

    import Lanttern.CurriculaFixtures

    @invalid_attrs %{name: nil}

    test "list_curriculum_items/1 returns all items" do
      curriculum_item = curriculum_item_fixture()
      assert Curricula.list_curriculum_items() == [curriculum_item]
    end

    test "list_curriculum_items/1 with preloads returns all curriculum_items with preloaded data" do
      curriculum_component = curriculum_component_fixture()

      curriculum_item =
        curriculum_item_fixture(%{curriculum_component_id: curriculum_component.id})

      [expected] = Curricula.list_curriculum_items(preloads: :curriculum_component)
      assert expected.id == curriculum_item.id
      assert expected.curriculum_component == curriculum_component
    end

    test "get_curriculum_item!/2 returns the item with given id" do
      curriculum_item = curriculum_item_fixture()
      assert Curricula.get_curriculum_item!(curriculum_item.id) == curriculum_item
    end

    test "get_curriculum_item!/2 with preloads returns the curriculum_item with given id and preloaded data" do
      curriculum_component = curriculum_component_fixture()

      curriculum_item =
        curriculum_item_fixture(%{curriculum_component_id: curriculum_component.id})

      expected =
        Curricula.get_curriculum_item!(curriculum_item.id, preloads: :curriculum_component)

      assert expected.id == curriculum_item.id
      assert expected.curriculum_component == curriculum_component
    end

    test "create_curriculum_item/1 with valid data creates a curriculum item" do
      curriculum_component = curriculum_component_fixture()

      valid_attrs = %{
        name: "some name",
        code: "some code",
        curriculum_component_id: curriculum_component.id
      }

      assert {:ok, %CurriculumItem{} = curriculum_item} =
               Curricula.create_curriculum_item(valid_attrs)

      assert curriculum_item.name == "some name"
      assert curriculum_item.code == "some code"
      assert curriculum_item.curriculum_component_id == curriculum_component.id
    end

    test "create_curriculum_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Curricula.create_curriculum_item(@invalid_attrs)
    end

    test "update_curriculum_item/2 with valid data updates the item" do
      curriculum_item = curriculum_item_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %CurriculumItem{} = curriculum_item} =
               Curricula.update_curriculum_item(curriculum_item, update_attrs)

      assert curriculum_item.name == "some updated name"
    end

    test "update_curriculum_item/2 with invalid data returns error changeset" do
      curriculum_item = curriculum_item_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Curricula.update_curriculum_item(curriculum_item, @invalid_attrs)

      assert curriculum_item == Curricula.get_curriculum_item!(curriculum_item.id)
    end

    test "delete_curriculum_item/1 deletes the item" do
      curriculum_item = curriculum_item_fixture()
      assert {:ok, %CurriculumItem{}} = Curricula.delete_curriculum_item(curriculum_item)

      assert_raise Ecto.NoResultsError, fn ->
        Curricula.get_curriculum_item!(curriculum_item.id)
      end
    end

    test "change_curriculum_item/1 returns a item changeset" do
      curriculum_item = curriculum_item_fixture()
      assert %Ecto.Changeset{} = Curricula.change_curriculum_item(curriculum_item)
    end
  end
end
