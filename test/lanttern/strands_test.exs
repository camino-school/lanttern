defmodule Lanttern.StrandsTest do
  use Lanttern.DataCase

  alias Lanttern.Repo
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

  describe "class_assignments" do
    alias Lanttern.Strands.ClassAssignment

    import Lanttern.Factory
    import Lanttern.IdentityFixtures, only: [staff_scope_fixture: 0]

    @invalid_attrs %{strand_id: nil, class_id: nil}

    test "list_strand_class_assignments/2 returns class assignments for given strand scoped to school" do
      scope = staff_scope_fixture()
      school = Repo.get!(Lanttern.Schools.School, scope.school_id)
      strand = insert(:strand)
      class = insert(:class, school: school)
      %{id: id} = insert(:class_assignment, strand: strand, class: class)
      _other_strand = insert(:class_assignment)

      assert [%ClassAssignment{id: ^id}] = Strands.list_strand_class_assignments(scope, strand.id)
    end

    test "list_strand_class_assignments/2 does not return assignments from other schools" do
      scope = staff_scope_fixture()
      strand = insert(:strand)
      _other_school_assignment = insert(:class_assignment, strand: strand)

      assert [] = Strands.list_strand_class_assignments(scope, strand.id)
    end

    test "list_strand_class_assignments/2 always preloads class" do
      scope = staff_scope_fixture()
      school = Repo.get!(Lanttern.Schools.School, scope.school_id)
      strand = insert(:strand)
      class = insert(:class, school: school)
      insert(:class_assignment, strand: strand, class: class)

      assert [%ClassAssignment{class: %Lanttern.Schools.Class{}}] =
               Strands.list_strand_class_assignments(scope, strand.id)
    end

    test "get_strand_class_assignment!/2 returns the class assignment with given id" do
      scope = staff_scope_fixture()
      school = Repo.get!(Lanttern.Schools.School, scope.school_id)
      class = insert(:class, school: school)
      %{id: id} = insert(:class_assignment, class: class)

      assert %ClassAssignment{id: ^id, class: %Lanttern.Schools.Class{}} =
               Strands.get_strand_class_assignment!(scope, id)
    end

    test "get_strand_class_assignment!/2 raises when class belongs to another school" do
      scope = staff_scope_fixture()
      %{id: id} = insert(:class_assignment)

      assert_raise Ecto.NoResultsError, fn ->
        Strands.get_strand_class_assignment!(scope, id)
      end
    end

    test "create_strand_class_assignment/2 with valid data creates a class assignment" do
      scope = staff_scope_fixture()
      school = Repo.get!(Lanttern.Schools.School, scope.school_id)
      strand = insert(:strand)
      class = insert(:class, school: school)
      valid_attrs = %{strand_id: strand.id, class_id: class.id}

      assert {:ok, %ClassAssignment{}} =
               Strands.create_strand_class_assignment(scope, valid_attrs)
    end

    test "create_strand_class_assignment/2 with invalid data returns error changeset" do
      scope = staff_scope_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Strands.create_strand_class_assignment(scope, @invalid_attrs)
    end

    test "create_strand_class_assignment/2 raises when scope is not staff" do
      scope = %Lanttern.Identity.Scope{profile_type: "student"}
      assert_raise MatchError, fn -> Strands.create_strand_class_assignment(scope, %{}) end
    end

    test "create_strand_class_assignment/2 raises when class belongs to another school" do
      scope = staff_scope_fixture()
      strand = insert(:strand)
      other_school = insert(:school)
      class = insert(:class, school: other_school)
      attrs = %{strand_id: strand.id, class_id: class.id}

      assert_raise MatchError, fn ->
        Strands.create_strand_class_assignment(scope, attrs)
      end
    end

    test "update_strand_class_assignment/3 with valid data updates the class assignment" do
      scope = staff_scope_fixture()
      school = Repo.get!(Lanttern.Schools.School, scope.school_id)
      class = insert(:class, school: school)
      assignment = insert(:class_assignment, class: class)
      new_class = insert(:class, school: school)
      update_attrs = %{class_id: new_class.id}

      assert {:ok, %ClassAssignment{class_id: new_class_id}} =
               Strands.update_strand_class_assignment(scope, assignment, update_attrs)

      assert new_class_id == new_class.id
    end

    test "update_strand_class_assignment/3 with invalid data returns error changeset" do
      scope = staff_scope_fixture()
      school = Repo.get!(Lanttern.Schools.School, scope.school_id)
      class = insert(:class, school: school)
      %{id: id} = assignment = insert(:class_assignment, class: class)

      assert {:error, %Ecto.Changeset{}} =
               Strands.update_strand_class_assignment(scope, assignment, @invalid_attrs)

      assert %ClassAssignment{id: ^id} = Strands.get_strand_class_assignment!(scope, id)
    end

    test "update_strand_class_assignment/3 raises when scope is not staff" do
      scope = %Lanttern.Identity.Scope{profile_type: "student"}
      assignment = insert(:class_assignment)

      assert_raise MatchError, fn ->
        Strands.update_strand_class_assignment(scope, assignment, %{})
      end
    end

    test "delete_strand_class_assignment/2 deletes the class assignment" do
      scope = staff_scope_fixture()
      school = Repo.get!(Lanttern.Schools.School, scope.school_id)
      class = insert(:class, school: school)
      %{id: id} = assignment = insert(:class_assignment, class: class)

      assert {:ok, %ClassAssignment{id: ^id}} =
               Strands.delete_strand_class_assignment(scope, assignment)

      assert_raise Ecto.NoResultsError, fn ->
        Strands.get_strand_class_assignment!(scope, id)
      end
    end

    test "delete_strand_class_assignment/2 raises when scope is not staff" do
      scope = %Lanttern.Identity.Scope{profile_type: "student"}
      assignment = insert(:class_assignment)

      assert_raise MatchError, fn ->
        Strands.delete_strand_class_assignment(scope, assignment)
      end
    end

    test "change_strand_class_assignment/3 returns a class assignment changeset" do
      scope = staff_scope_fixture()
      assignment = insert(:class_assignment)

      assert %Ecto.Changeset{} = Strands.change_strand_class_assignment(scope, assignment)
    end
  end
end
