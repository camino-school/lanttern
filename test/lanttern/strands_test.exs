defmodule Lanttern.StrandsTest do
  use Lanttern.DataCase

  alias Lanttern.Strands

  describe "strand_curriculum_items" do
    alias Lanttern.Strands.StrandCurriculumItem

    import Lanttern.Factory
    import Lanttern.IdentityFixtures, only: [staff_scope_fixture: 0]

    @invalid_attrs %{position: nil}

    test "list_strand_curriculum_items/2 returns strand_curriculum_items for given strand" do
      scope = staff_scope_fixture()
      strand = insert(:strand)
      %{id: id} = insert(:strand_curriculum_item, strand: strand)
      _other = insert(:strand_curriculum_item)

      assert [%StrandCurriculumItem{id: ^id}] =
               Strands.list_strand_curriculum_items(scope, strand.id)
    end

    test "get_strand_curriculum_item!/2 returns the strand_curriculum_item with given id" do
      scope = staff_scope_fixture()
      %{id: id} = insert(:strand_curriculum_item)
      assert %StrandCurriculumItem{id: ^id} = Strands.get_strand_curriculum_item!(scope, id)
    end

    test "create_strand_curriculum_item/2 with valid data creates a strand_curriculum_item" do
      scope = staff_scope_fixture()
      strand = insert(:strand)
      curriculum_item = insert(:curriculum_item)
      valid_attrs = %{position: 42, strand_id: strand.id, curriculum_item_id: curriculum_item.id}

      assert {:ok, %StrandCurriculumItem{position: 42}} =
               Strands.create_strand_curriculum_item(scope, valid_attrs)
    end

    test "create_strand_curriculum_item/2 with invalid data returns error changeset" do
      scope = staff_scope_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Strands.create_strand_curriculum_item(scope, @invalid_attrs)
    end

    test "create_strand_curriculum_item/2 raises when scope is not staff" do
      scope = %Lanttern.Identity.Scope{profile_type: "student"}
      assert_raise MatchError, fn -> Strands.create_strand_curriculum_item(scope, %{}) end
    end

    test "update_strand_curriculum_item/3 with valid data updates the strand_curriculum_item" do
      scope = staff_scope_fixture()
      strand_curriculum_item = insert(:strand_curriculum_item)

      assert {:ok, %StrandCurriculumItem{position: 43}} =
               Strands.update_strand_curriculum_item(scope, strand_curriculum_item, %{
                 position: 43
               })
    end

    test "update_strand_curriculum_item/3 with invalid data returns error changeset" do
      scope = staff_scope_fixture()
      %{id: id} = strand_curriculum_item = insert(:strand_curriculum_item)

      assert {:error, %Ecto.Changeset{}} =
               Strands.update_strand_curriculum_item(
                 scope,
                 strand_curriculum_item,
                 @invalid_attrs
               )

      assert %StrandCurriculumItem{id: ^id} = Strands.get_strand_curriculum_item!(scope, id)
    end

    test "update_strand_curriculum_item/3 raises when scope is not staff" do
      scope = %Lanttern.Identity.Scope{profile_type: "student"}
      strand_curriculum_item = insert(:strand_curriculum_item)

      assert_raise MatchError, fn ->
        Strands.update_strand_curriculum_item(scope, strand_curriculum_item, %{})
      end
    end

    test "delete_strand_curriculum_item/2 deletes the strand_curriculum_item" do
      scope = staff_scope_fixture()
      %{id: id} = strand_curriculum_item = insert(:strand_curriculum_item)

      assert {:ok, %StrandCurriculumItem{id: ^id}} =
               Strands.delete_strand_curriculum_item(scope, strand_curriculum_item)

      assert_raise Ecto.NoResultsError, fn ->
        Strands.get_strand_curriculum_item!(scope, id)
      end
    end

    test "delete_strand_curriculum_item/2 raises when scope is not staff" do
      scope = %Lanttern.Identity.Scope{profile_type: "student"}
      strand_curriculum_item = insert(:strand_curriculum_item)

      assert_raise MatchError, fn ->
        Strands.delete_strand_curriculum_item(scope, strand_curriculum_item)
      end
    end

    test "change_strand_curriculum_item/2 returns a strand_curriculum_item changeset" do
      scope = staff_scope_fixture()
      strand_curriculum_item = insert(:strand_curriculum_item)

      assert %Ecto.Changeset{} =
               Strands.change_strand_curriculum_item(scope, strand_curriculum_item)
    end
  end
end
