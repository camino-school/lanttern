defmodule Lanttern.CurriculaTest do
  alias Lanttern.AssessmentsFixtures
  use Lanttern.DataCase

  alias Lanttern.Curricula

  import Lanttern.Factory
  import Lanttern.IdentityFixtures

  describe "curricula" do
    alias Lanttern.Curricula.Curriculum

    @invalid_attrs %{name: nil}

    test "list_curricula/1 returns all curricula for the scope's school ordered alphabetically" do
      scope = scope_fixture(permissions: ["curriculum_management"])

      curriculum_b = insert(:curriculum, name: "BBB", school_id: scope.school_id)
      curriculum_a = insert(:curriculum, name: "AAA", school_id: scope.school_id)
      curriculum_c = insert(:curriculum, name: "CCC", school_id: scope.school_id)

      # other school's curriculum should not appear
      insert(:curriculum, name: "DDD")

      result = Curricula.list_curricula(scope)
      assert Enum.map(result, & &1.id) == [curriculum_a.id, curriculum_b.id, curriculum_c.id]
    end

    test "get_curriculum!/2 returns the curriculum with given id" do
      scope = scope_fixture()

      curriculum = insert(:curriculum, school_id: scope.school_id)
      assert Curricula.get_curriculum!(scope, curriculum.id).id == curriculum.id
    end

    test "get_curriculum!/2 raises for curriculum from another school" do
      scope = scope_fixture()
      curriculum = insert(:curriculum)

      assert_raise Ecto.NoResultsError, fn ->
        Curricula.get_curriculum!(scope, curriculum.id)
      end
    end

    test "create_curriculum/2 with valid data creates a curriculum" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      valid_attrs = %{name: "some name"}

      assert {:ok, %Curriculum{} = curriculum} = Curricula.create_curriculum(scope, valid_attrs)
      assert curriculum.name == "some name"
      assert curriculum.school_id == scope.school_id
    end

    test "create_curriculum/2 with invalid data returns error changeset" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      assert {:error, %Ecto.Changeset{}} = Curricula.create_curriculum(scope, @invalid_attrs)
    end

    test "create_curriculum/2 raises without permission" do
      scope = scope_fixture()

      assert_raise MatchError, fn ->
        Curricula.create_curriculum(scope, %{name: "some name"})
      end
    end

    test "update_curriculum/3 with valid data updates the curriculum" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      curriculum = insert(:curriculum, school_id: scope.school_id)
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Curriculum{} = curriculum} =
               Curricula.update_curriculum(scope, curriculum, update_attrs)

      assert curriculum.name == "some updated name"
    end

    test "update_curriculum/3 with invalid data returns error changeset" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      curriculum = insert(:curriculum, school_id: scope.school_id)

      assert {:error, %Ecto.Changeset{}} =
               Curricula.update_curriculum(scope, curriculum, @invalid_attrs)

      assert curriculum.id == Curricula.get_curriculum!(scope, curriculum.id).id
    end

    test "update_curriculum/3 raises without permission" do
      scope = scope_fixture()
      curriculum = insert(:curriculum, school_id: scope.school_id)

      assert_raise MatchError, fn ->
        Curricula.update_curriculum(scope, curriculum, %{name: "updated"})
      end
    end

    test "delete_curriculum/2 deletes the curriculum" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      curriculum = insert(:curriculum, school_id: scope.school_id)

      assert {:ok, %Curriculum{}} = Curricula.delete_curriculum(scope, curriculum)

      assert_raise Ecto.NoResultsError, fn ->
        Curricula.get_curriculum!(scope, curriculum.id)
      end
    end

    test "change_curriculum/3 returns a curriculum changeset" do
      scope = scope_fixture()
      curriculum = insert(:curriculum, school_id: scope.school_id)
      assert %Ecto.Changeset{} = Curricula.change_curriculum(scope, curriculum)
    end
  end

  describe "curriculum_components" do
    alias Lanttern.Curricula.CurriculumComponent

    @invalid_attrs %{code: nil, name: nil}

    test "list_curriculum_components/2 returns all curriculum_components for the scope's school ordered by position" do
      scope = scope_fixture()

      curriculum_component_2 =
        insert(:curriculum_component, position: 2, school_id: scope.school_id)

      curriculum_component_1 =
        insert(:curriculum_component, position: 1, school_id: scope.school_id)

      curriculum_component_3 =
        insert(:curriculum_component, position: 3, school_id: scope.school_id)

      # other school's component should not appear
      insert(:curriculum_component)

      result = Curricula.list_curriculum_components(scope)

      assert Enum.map(result, & &1.id) == [
               curriculum_component_1.id,
               curriculum_component_2.id,
               curriculum_component_3.id
             ]
    end

    test "list_curriculum_components/2 with preloads returns all curriculum_components with preloaded data" do
      scope = scope_fixture()
      curriculum = insert(:curriculum, school_id: scope.school_id)

      curriculum_component =
        insert(:curriculum_component,
          curriculum_id: curriculum.id,
          school_id: scope.school_id
        )

      [expected] = Curricula.list_curriculum_components(scope, preloads: :curriculum)
      assert expected.id == curriculum_component.id
      assert expected.curriculum == curriculum
    end

    test "list_curriculum_components/2 with curricula filter returns only curriculum_components for given curricula" do
      scope = scope_fixture()
      curriculum = insert(:curriculum, school_id: scope.school_id)

      curriculum_component =
        insert(:curriculum_component,
          curriculum_id: curriculum.id,
          school_id: scope.school_id
        )

      # extra curriculum component for filter test
      insert(:curriculum_component, school_id: scope.school_id)

      [expected] =
        Curricula.list_curriculum_components(scope, curricula_ids: [curriculum.id])

      assert expected.id == curriculum_component.id
    end

    test "get_curriculum_component!/3 returns the curriculum_component with given id" do
      scope = scope_fixture()
      curriculum_component = insert(:curriculum_component, school_id: scope.school_id)

      assert Curricula.get_curriculum_component!(scope, curriculum_component.id).id ==
               curriculum_component.id
    end

    test "get_curriculum_component!/3 with preloads returns the curriculum_component with given id and preloaded data" do
      scope = scope_fixture()
      curriculum = insert(:curriculum, school_id: scope.school_id)

      curriculum_component =
        insert(:curriculum_component,
          curriculum_id: curriculum.id,
          school_id: scope.school_id
        )

      expected =
        Curricula.get_curriculum_component!(scope, curriculum_component.id, preloads: :curriculum)

      assert expected.id == curriculum_component.id
      assert expected.curriculum == curriculum
    end

    test "create_curriculum_component/2 with valid data creates a curriculum_component" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      curriculum = insert(:curriculum, school_id: scope.school_id)
      valid_attrs = %{code: "some code", name: "some name", curriculum_id: curriculum.id}

      assert {:ok, %CurriculumComponent{} = curriculum_component} =
               Curricula.create_curriculum_component(scope, valid_attrs)

      assert curriculum_component.code == "some code"
      assert curriculum_component.name == "some name"
      assert curriculum_component.curriculum_id == curriculum.id
      assert curriculum_component.school_id == scope.school_id
    end

    test "create_curriculum_component/2 with invalid data returns error changeset" do
      scope = scope_fixture(permissions: ["curriculum_management"])

      assert {:error, %Ecto.Changeset{}} =
               Curricula.create_curriculum_component(scope, @invalid_attrs)
    end

    test "update_curriculum_component/3 with valid data updates the curriculum_component" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      curriculum_component = insert(:curriculum_component, school_id: scope.school_id)
      update_attrs = %{code: "some updated code", name: "some updated name"}

      assert {:ok, %CurriculumComponent{} = curriculum_component} =
               Curricula.update_curriculum_component(scope, curriculum_component, update_attrs)

      assert curriculum_component.code == "some updated code"
      assert curriculum_component.name == "some updated name"
    end

    test "update_curriculum_component/3 with invalid data returns error changeset" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      curriculum_component = insert(:curriculum_component, school_id: scope.school_id)

      assert {:error, %Ecto.Changeset{}} =
               Curricula.update_curriculum_component(scope, curriculum_component, @invalid_attrs)

      assert curriculum_component.id ==
               Curricula.get_curriculum_component!(scope, curriculum_component.id).id
    end

    test "delete_curriculum_component/2 deletes the curriculum_component" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      curriculum_component = insert(:curriculum_component, school_id: scope.school_id)

      assert {:ok, %CurriculumComponent{}} =
               Curricula.delete_curriculum_component(scope, curriculum_component)

      assert_raise Ecto.NoResultsError, fn ->
        Curricula.get_curriculum_component!(scope, curriculum_component.id)
      end
    end

    test "change_curriculum_component/3 returns a curriculum_component changeset" do
      scope = scope_fixture()
      curriculum_component = insert(:curriculum_component, school_id: scope.school_id)

      assert %Ecto.Changeset{} =
               Curricula.change_curriculum_component(scope, curriculum_component)
    end
  end

  describe "curriculum_items" do
    alias Lanttern.Curricula.CurriculumItem

    import Lanttern.TaxonomyFixtures

    @invalid_attrs %{name: nil}

    # Helper to create curriculum items with many-to-many associations (subjects/years).
    # ExMachina's `insert` can't handle virtual fields that drive join table inserts,
    # so we go through the context function instead.
    defp insert_curriculum_item_with_associations(scope, attrs) do
      cc =
        if Map.has_key?(attrs, :curriculum_component_id) do
          nil
        else
          insert(:curriculum_component, school_id: scope.school_id)
        end

      write_scope =
        scope
        |> Lanttern.Identity.Scope.put_permission("curriculum_management")

      context_attrs =
        %{
          name: Ecto.UUID.generate(),
          code: Ecto.UUID.generate(),
          curriculum_component_id: cc && cc.id
        }
        |> Map.merge(attrs)

      {:ok, curriculum_item} = Curricula.create_curriculum_item(write_scope, context_attrs)
      curriculum_item
    end

    test "list_curriculum_items/2 returns all items for the scope's school" do
      scope = scope_fixture()
      curriculum_item = insert(:curriculum_item, school_id: scope.school_id)

      # other school's item should not appear
      insert(:curriculum_item)

      assert [expected] = Curricula.list_curriculum_items(scope)
      assert expected.id == curriculum_item.id
    end

    test "list_curriculum_items/2 with preloads returns all curriculum_items with preloaded data" do
      scope = scope_fixture()

      curriculum_component =
        insert(:curriculum_component, school_id: scope.school_id)

      subject = subject_fixture()
      year = year_fixture()

      curriculum_item =
        insert_curriculum_item_with_associations(scope, %{
          curriculum_component_id: curriculum_component.id,
          subjects_ids: [subject.id],
          years_ids: [year.id]
        })

      [expected] =
        Curricula.list_curriculum_items(scope,
          preloads: [:curriculum_component, :subjects, :years]
        )

      assert expected.id == curriculum_item.id
      assert expected.curriculum_component.id == curriculum_component.id
      assert expected.subjects == [subject]
      assert expected.years == [year]
    end

    test "list_curriculum_items/2 with component filters returns all curriculum_items of the given components" do
      scope = scope_fixture()

      curriculum_component =
        insert(:curriculum_component, school_id: scope.school_id)

      curriculum_item =
        insert(:curriculum_item,
          curriculum_component_id: curriculum_component.id,
          school_id: scope.school_id
        )

      # extra item in same school for filter test
      insert(:curriculum_item, school_id: scope.school_id)

      [expected] =
        Curricula.list_curriculum_items(scope, components_ids: [curriculum_component.id])

      assert expected.id == curriculum_item.id
    end

    test "list_curriculum_items/2 with filters returns all curriculum_items filtered by given fields" do
      scope = scope_fixture(permissions: ["curriculum_management"])

      subject = subject_fixture()
      other_subject = subject_fixture()
      year = year_fixture()
      other_year = year_fixture()

      curriculum_component =
        insert(:curriculum_component, school_id: scope.school_id)

      curriculum_item =
        insert_curriculum_item_with_associations(scope, %{
          curriculum_component_id: curriculum_component.id,
          subjects_ids: [subject.id],
          years_ids: [year.id]
        })

      # create extra items for filtering test
      insert_curriculum_item_with_associations(scope, %{
        curriculum_component_id: curriculum_component.id,
        subjects_ids: [subject.id],
        years_ids: [other_year.id]
      })

      insert_curriculum_item_with_associations(scope, %{
        curriculum_component_id: curriculum_component.id,
        subjects_ids: [other_subject.id],
        years_ids: [year.id]
      })

      insert_curriculum_item_with_associations(scope, %{
        curriculum_component_id: curriculum_component.id,
        subjects_ids: [other_subject.id],
        years_ids: [other_year.id]
      })

      [expected] =
        Curricula.list_curriculum_items(scope, subjects_ids: [subject.id], years_ids: [year.id])

      assert expected.id == curriculum_item.id
    end

    test "search_curriculum_items/3 returns all items matched by search" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      cc = insert(:curriculum_component, school_id: scope.school_id)

      _curriculum_item_1 =
        insert(:curriculum_item, %{
          name: "lorem ipsum xolor sit amet",
          curriculum_component_id: cc.id,
          school_id: scope.school_id
        })

      curriculum_item_2 =
        insert(:curriculum_item, %{
          name: "lorem ipsum dolor sit amet",
          curriculum_component_id: cc.id,
          school_id: scope.school_id
        })

      curriculum_item_3 =
        insert(:curriculum_item, %{
          name: "lorem ipsum dolorxxx sit amet",
          curriculum_component_id: cc.id,
          school_id: scope.school_id
        })

      _curriculum_item_4 =
        insert(:curriculum_item, %{
          name: "lorem ipsum xxxxx sit amet",
          curriculum_component_id: cc.id,
          school_id: scope.school_id
        })

      assert [expected_curriculum_item_2, expected_curriculum_item_3] =
               Curricula.search_curriculum_items(scope, "dolor")

      assert expected_curriculum_item_2.id == curriculum_item_2.id
      assert expected_curriculum_item_3.id == curriculum_item_3.id
    end

    test "search_curriculum_items/3 with #id returns item with id" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      cc = insert(:curriculum_component, school_id: scope.school_id)

      curriculum_item =
        insert(:curriculum_item, curriculum_component_id: cc.id, school_id: scope.school_id)

      insert(:curriculum_item, curriculum_component_id: cc.id, school_id: scope.school_id)

      [expected] = Curricula.search_curriculum_items(scope, "##{curriculum_item.id}")

      assert expected.id == curriculum_item.id
    end

    test "search_curriculum_items/3 with (code) returns item with code" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      cc = insert(:curriculum_component, school_id: scope.school_id)

      curriculum_item =
        insert(:curriculum_item,
          code: "abcd",
          curriculum_component_id: cc.id,
          school_id: scope.school_id
        )

      insert(:curriculum_item, curriculum_component_id: cc.id, school_id: scope.school_id)

      [expected] = Curricula.search_curriculum_items(scope, "(abcd)")

      assert expected.id == curriculum_item.id
    end

    test "search_curriculum_items/3 with preloads returns all search results with preloaded data" do
      scope = scope_fixture(permissions: ["curriculum_management"])

      curriculum_component =
        insert(:curriculum_component, school_id: scope.school_id)

      subject = subject_fixture()
      year = year_fixture()

      curriculum_item =
        insert_curriculum_item_with_associations(scope, %{
          name: "abcdefg",
          curriculum_component_id: curriculum_component.id,
          subjects_ids: [subject.id],
          years_ids: [year.id]
        })

      insert_curriculum_item_with_associations(scope, %{
        name: "search won't work here",
        curriculum_component_id: curriculum_component.id
      })

      [expected] =
        Curricula.search_curriculum_items(scope, "abcdefg",
          preloads: [:curriculum_component, :subjects, :years]
        )

      assert expected.id == curriculum_item.id
      assert expected.curriculum_component.id == curriculum_component.id
      assert expected.subjects == [subject]
      assert expected.years == [year]
    end

    test "search_curriculum_items/3 with filters returns results filtered by given fields" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      cc = insert(:curriculum_component, school_id: scope.school_id)

      subject = subject_fixture()
      other_subject = subject_fixture()
      year = year_fixture()
      other_year = year_fixture()

      curriculum_item =
        insert_curriculum_item_with_associations(scope, %{
          name: "abcde",
          curriculum_component_id: cc.id,
          subjects_ids: [subject.id],
          years_ids: [year.id]
        })

      # create extra items for filtering test
      insert_curriculum_item_with_associations(scope, %{
        name: "abcde2",
        curriculum_component_id: cc.id,
        subjects_ids: [subject.id],
        years_ids: [other_year.id]
      })

      insert_curriculum_item_with_associations(scope, %{
        name: "abcde3",
        curriculum_component_id: cc.id,
        subjects_ids: [other_subject.id],
        years_ids: [year.id]
      })

      insert_curriculum_item_with_associations(scope, %{
        name: "abcde4",
        curriculum_component_id: cc.id,
        subjects_ids: [other_subject.id],
        years_ids: [other_year.id]
      })

      insert_curriculum_item_with_associations(scope, %{
        name: "zzzzz",
        curriculum_component_id: cc.id,
        subjects_ids: [subject.id],
        years_ids: [year.id]
      })

      [expected] =
        Curricula.search_curriculum_items(scope, "abcde",
          subjects_ids: [subject.id],
          years_ids: [year.id]
        )

      assert expected.id == curriculum_item.id
    end

    test "get_curriculum_item!/3 returns the item with given id" do
      scope = scope_fixture()
      curriculum_item = insert(:curriculum_item, school_id: scope.school_id)
      assert Curricula.get_curriculum_item!(scope, curriculum_item.id).id == curriculum_item.id
    end

    test "get_curriculum_item!/3 with preloads returns the curriculum_item with given id and preloaded data" do
      scope = scope_fixture()

      curriculum_component =
        insert(:curriculum_component, school_id: scope.school_id)

      subject = subject_fixture()
      year = year_fixture()

      curriculum_item =
        insert_curriculum_item_with_associations(scope, %{
          curriculum_component_id: curriculum_component.id,
          subjects_ids: [subject.id],
          years_ids: [year.id]
        })

      expected =
        Curricula.get_curriculum_item!(scope, curriculum_item.id,
          preloads: [:curriculum_component, :subjects, :years]
        )

      assert expected.id == curriculum_item.id
      assert expected.curriculum_component.id == curriculum_component.id
      assert expected.subjects == [subject]
      assert expected.years == [year]
    end

    test "create_curriculum_item/2 with valid data creates a curriculum item" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      curriculum_component = insert(:curriculum_component, school_id: scope.school_id)
      subject = subject_fixture()
      year = year_fixture()

      valid_attrs = %{
        name: "some name",
        code: "some code",
        curriculum_component_id: curriculum_component.id,
        subjects_ids: [subject.id],
        years_ids: [year.id]
      }

      assert {:ok, %CurriculumItem{} = curriculum_item} =
               Curricula.create_curriculum_item(scope, valid_attrs)

      assert curriculum_item.name == "some name"
      assert curriculum_item.code == "some code"
      assert curriculum_item.curriculum_component_id == curriculum_component.id
      assert curriculum_item.school_id == scope.school_id
      assert curriculum_item.subjects == [subject]
      assert curriculum_item.years == [year]
    end

    test "create_curriculum_item/2 with invalid data returns error changeset" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      assert {:error, %Ecto.Changeset{}} = Curricula.create_curriculum_item(scope, @invalid_attrs)
    end

    test "create_curriculum_item/2 raises without permission" do
      scope = scope_fixture()

      assert_raise MatchError, fn ->
        Curricula.create_curriculum_item(scope, %{name: "some name"})
      end
    end

    test "update_curriculum_item/3 with valid data updates the item" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      curriculum_item = insert(:curriculum_item, school_id: scope.school_id)
      update_attrs = %{name: "some updated name"}

      assert {:ok, %CurriculumItem{} = curriculum_item} =
               Curricula.update_curriculum_item(scope, curriculum_item, update_attrs)

      assert curriculum_item.name == "some updated name"
    end

    test "update_curriculum_item/3 with valid data containing subjects and years updates the curriculum item" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      cc = insert(:curriculum_component, school_id: scope.school_id)

      subject_1 = subject_fixture()
      subject_2 = subject_fixture()
      subject_3 = subject_fixture()

      year_1 = year_fixture()
      year_2 = year_fixture()
      year_3 = year_fixture()

      curriculum_item =
        insert_curriculum_item_with_associations(scope, %{
          curriculum_component_id: cc.id,
          subjects_ids: [subject_1.id, subject_2.id],
          years_ids: [year_1.id, year_2.id]
        })

      update_attrs = %{
        name: "some updated name",
        subjects_ids: [subject_1.id, subject_3.id],
        years_ids: [year_3.id]
      }

      assert {:ok, %CurriculumItem{} = curriculum_item} =
               Curricula.update_curriculum_item(scope, curriculum_item, update_attrs)

      assert curriculum_item.name == "some updated name"
      assert length(curriculum_item.subjects) == 2
      assert Enum.find(curriculum_item.subjects, fn s -> s.id == subject_1.id end)
      assert Enum.find(curriculum_item.subjects, fn s -> s.id == subject_3.id end)
      assert length(curriculum_item.years) == 1
      assert Enum.find(curriculum_item.years, fn y -> y.id == year_3.id end)
    end

    test "update_curriculum_item/3 with invalid data returns error changeset" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      curriculum_item = insert(:curriculum_item, school_id: scope.school_id)

      assert {:error, %Ecto.Changeset{}} =
               Curricula.update_curriculum_item(scope, curriculum_item, @invalid_attrs)

      assert curriculum_item.id == Curricula.get_curriculum_item!(scope, curriculum_item.id).id
    end

    test "delete_curriculum_item/2 deletes the item" do
      scope = scope_fixture(permissions: ["curriculum_management"])
      curriculum_item = insert(:curriculum_item, school_id: scope.school_id)

      assert {:ok, %CurriculumItem{}} =
               Curricula.delete_curriculum_item(scope, curriculum_item)

      assert_raise Ecto.NoResultsError, fn ->
        Curricula.get_curriculum_item!(scope, curriculum_item.id)
      end
    end

    test "change_curriculum_item/3 returns a item changeset" do
      scope = scope_fixture()
      curriculum_item = insert(:curriculum_item, school_id: scope.school_id)
      assert %Ecto.Changeset{} = Curricula.change_curriculum_item(scope, curriculum_item)
    end
  end

  describe "curriculum_relationships" do
    alias Lanttern.Curricula.CurriculumRelationship

    @invalid_attrs %{type: nil}

    test "list_curriculum_relationships/1 returns all curriculum_relationships" do
      curriculum_relationship = insert(:curriculum_relationship)
      assert [result] = Curricula.list_curriculum_relationships()
      assert result.id == curriculum_relationship.id
    end

    test "list_curriculum_relationships/1 with preloads returns all curriculum_relationships with preloaded data" do
      curriculum_item_a = insert(:curriculum_item)
      curriculum_item_b = insert(:curriculum_item)

      curriculum_relationship =
        insert(:curriculum_relationship, %{
          curriculum_item_a_id: curriculum_item_a.id,
          curriculum_item_b_id: curriculum_item_b.id
        })

      [expected] =
        Curricula.list_curriculum_relationships(
          preloads: [:curriculum_item_a, :curriculum_item_b]
        )

      assert expected.id == curriculum_relationship.id
      assert expected.curriculum_item_a.id == curriculum_item_a.id
      assert expected.curriculum_item_b.id == curriculum_item_b.id
    end

    test "get_curriculum_relationship!/2 returns the curriculum_relationship with given id" do
      curriculum_relationship = insert(:curriculum_relationship)

      assert Curricula.get_curriculum_relationship!(curriculum_relationship.id).id ==
               curriculum_relationship.id
    end

    test "get_curriculum_relationship!/2 with preloads returns the curriculum_relationship with given id and preloaded data" do
      curriculum_item_a = insert(:curriculum_item)
      curriculum_item_b = insert(:curriculum_item)

      curriculum_relationship =
        insert(:curriculum_relationship, %{
          curriculum_item_a_id: curriculum_item_a.id,
          curriculum_item_b_id: curriculum_item_b.id
        })

      expected =
        Curricula.get_curriculum_relationship!(curriculum_relationship.id,
          preloads: [:curriculum_item_a, :curriculum_item_b]
        )

      assert expected.id == curriculum_relationship.id
      assert expected.curriculum_item_a.id == curriculum_item_a.id
      assert expected.curriculum_item_b.id == curriculum_item_b.id
    end

    test "create_curriculum_relationship/1 with valid data creates a curriculum_relationship" do
      curriculum_item_a = insert(:curriculum_item)
      curriculum_item_b = insert(:curriculum_item)

      valid_attrs = %{
        curriculum_item_a_id: curriculum_item_a.id,
        curriculum_item_b_id: curriculum_item_b.id,
        type: "hierarchical"
      }

      assert {:ok, %CurriculumRelationship{} = curriculum_relationship} =
               Curricula.create_curriculum_relationship(valid_attrs)

      assert curriculum_relationship.type == "hierarchical"
      assert curriculum_relationship.curriculum_item_a_id == curriculum_item_a.id
      assert curriculum_relationship.curriculum_item_b_id == curriculum_item_b.id
    end

    test "create_curriculum_relationship/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Curricula.create_curriculum_relationship(@invalid_attrs)
    end

    test "update_curriculum_relationship/2 with valid data updates the curriculum_relationship" do
      curriculum_relationship = insert(:curriculum_relationship)
      update_attrs = %{type: "hierarchical"}

      assert {:ok, %CurriculumRelationship{} = curriculum_relationship} =
               Curricula.update_curriculum_relationship(curriculum_relationship, update_attrs)

      assert curriculum_relationship.type == "hierarchical"
    end

    test "update_curriculum_relationship/2 with invalid data returns error changeset" do
      curriculum_relationship = insert(:curriculum_relationship)

      assert {:error, %Ecto.Changeset{}} =
               Curricula.update_curriculum_relationship(curriculum_relationship, @invalid_attrs)

      assert curriculum_relationship.id ==
               Curricula.get_curriculum_relationship!(curriculum_relationship.id).id
    end

    test "delete_curriculum_relationship/1 deletes the curriculum_relationship" do
      curriculum_relationship = insert(:curriculum_relationship)

      assert {:ok, %CurriculumRelationship{}} =
               Curricula.delete_curriculum_relationship(curriculum_relationship)

      assert_raise Ecto.NoResultsError, fn ->
        Curricula.get_curriculum_relationship!(curriculum_relationship.id)
      end
    end

    test "change_curriculum_relationship/1 returns a curriculum_relationship changeset" do
      curriculum_relationship = insert(:curriculum_relationship)

      assert %Ecto.Changeset{} =
               Curricula.change_curriculum_relationship(curriculum_relationship)
    end
  end

  describe "strand curriculum items" do
    import Lanttern.AssessmentsFixtures
    import Lanttern.LearningContextFixtures

    test "list_strand_curriculum_items/1 returns all items linked to the given strand" do
      # create items "inverted" to test order by position
      curriculum_item_2 = insert(:curriculum_item)
      curriculum_item_1 = insert(:curriculum_item)
      curriculum_item_diff = insert(:curriculum_item)

      strand = strand_fixture()

      AssessmentsFixtures.assessment_point_fixture(%{
        strand_id: strand.id,
        curriculum_item_id: curriculum_item_1.id,
        rubric_id: Lanttern.RubricsFixtures.rubric_fixture().id
      })

      AssessmentsFixtures.assessment_point_fixture(%{
        strand_id: strand.id,
        curriculum_item_id: curriculum_item_2.id
      })

      AssessmentsFixtures.assessment_point_fixture(%{
        strand_id: strand.id,
        curriculum_item_id: curriculum_item_diff.id,
        is_differentiation: true
      })

      # extra curriculum items for testing
      insert(:curriculum_item)
      other_curriculum_item = insert(:curriculum_item)

      AssessmentsFixtures.assessment_point_fixture(%{
        strand_id: strand_fixture().id,
        curriculum_item_id: other_curriculum_item.id
      })

      assert [expected_1, expected_2, expected_diff] =
               Curricula.list_strand_curriculum_items(strand.id)

      assert curriculum_item_1.id == expected_1.id
      assert expected_1.has_rubric
      assert curriculum_item_2.id == expected_2.id
      assert curriculum_item_diff.id == expected_diff.id
      assert expected_diff.is_differentiation
    end
  end

  describe "moment curriculum items" do
    import Lanttern.AssessmentsFixtures
    import Lanttern.LearningContextFixtures

    test "list_moment_curriculum_items/2 returns all items linked to the given moment" do
      curriculum_item_a = insert(:curriculum_item, name: "AAA")
      curriculum_item_b = insert(:curriculum_item, name: "BBB")

      moment = moment_fixture()

      assessment_point_fixture(%{
        moment_id: moment.id,
        curriculum_item_id: curriculum_item_a.id
      })

      assessment_point_fixture(%{
        moment_id: moment.id,
        curriculum_item_id: curriculum_item_b.id
      })

      # extra curriculum items for testing
      insert(:curriculum_item)
      other_curriculum_item = insert(:curriculum_item)
      other_moment = moment_fixture()

      assessment_point_fixture(%{
        moment_id: other_moment.id,
        curriculum_items: [%{curriculum_item_id: other_curriculum_item.id}]
      })

      assert [expected_ci_a, expected_ci_b] =
               Curricula.list_moment_curriculum_items(moment.id)

      assert expected_ci_a.id == curriculum_item_a.id
      assert expected_ci_b.id == curriculum_item_b.id
    end
  end
end
