defmodule Lanttern.CurriculaTest do
  use Lanttern.DataCase

  alias Lanttern.Curricula

  describe "items" do
    alias Lanttern.Curricula.Item

    import Lanttern.CurriculaFixtures

    @invalid_attrs %{name: nil}

    test "list_items/0 returns all items" do
      item = item_fixture()
      assert Curricula.list_items() == [item]
    end

    test "get_item!/1 returns the item with given id" do
      item = item_fixture()
      assert Curricula.get_item!(item.id) == item
    end

    test "create_item/1 with valid data creates a item" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Item{} = item} = Curricula.create_item(valid_attrs)
      assert item.name == "some name"
    end

    test "create_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Curricula.create_item(@invalid_attrs)
    end

    test "update_item/2 with valid data updates the item" do
      item = item_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Item{} = item} = Curricula.update_item(item, update_attrs)
      assert item.name == "some updated name"
    end

    test "update_item/2 with invalid data returns error changeset" do
      item = item_fixture()
      assert {:error, %Ecto.Changeset{}} = Curricula.update_item(item, @invalid_attrs)
      assert item == Curricula.get_item!(item.id)
    end

    test "delete_item/1 deletes the item" do
      item = item_fixture()
      assert {:ok, %Item{}} = Curricula.delete_item(item)
      assert_raise Ecto.NoResultsError, fn -> Curricula.get_item!(item.id) end
    end

    test "change_item/1 returns a item changeset" do
      item = item_fixture()
      assert %Ecto.Changeset{} = Curricula.change_item(item)
    end
  end

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

      assert {:ok, %Curriculum{} = curriculum} = Curricula.update_curriculum(curriculum, update_attrs)
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
end
