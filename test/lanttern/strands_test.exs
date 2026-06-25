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

    test "sync_strand_class_assignments/3 inserts new and deletes removed assignments" do
      scope = staff_scope_fixture()
      school = Repo.get!(Lanttern.Schools.School, scope.school_id)
      strand = insert(:strand)
      class_keep = insert(:class, school: school)
      class_remove = insert(:class, school: school)
      class_add = insert(:class, school: school)

      insert(:class_assignment, strand: strand, class: class_keep)
      insert(:class_assignment, strand: strand, class: class_remove)

      assert :ok =
               Strands.sync_strand_class_assignments(scope, strand.id, [
                 class_keep.id,
                 class_add.id
               ])

      result = Strands.list_strand_class_assignments(scope, strand.id)
      result_class_ids = Enum.map(result, & &1.class_id)

      assert class_keep.id in result_class_ids
      assert class_add.id in result_class_ids
      refute class_remove.id in result_class_ids
    end

    test "sync_strand_class_assignments/3 is a no-op when class IDs are unchanged" do
      scope = staff_scope_fixture()
      school = Repo.get!(Lanttern.Schools.School, scope.school_id)
      strand = insert(:strand)
      class = insert(:class, school: school)
      %{id: id} = insert(:class_assignment, strand: strand, class: class)

      assert :ok = Strands.sync_strand_class_assignments(scope, strand.id, [class.id])

      assert [%ClassAssignment{id: ^id}] = Strands.list_strand_class_assignments(scope, strand.id)
    end

    test "sync_strand_class_assignments/3 removes all assignments when given empty list" do
      scope = staff_scope_fixture()
      school = Repo.get!(Lanttern.Schools.School, scope.school_id)
      strand = insert(:strand)
      class = insert(:class, school: school)
      insert(:class_assignment, strand: strand, class: class)

      assert :ok = Strands.sync_strand_class_assignments(scope, strand.id, [])

      assert [] = Strands.list_strand_class_assignments(scope, strand.id)
    end

    test "sync_strand_class_assignments/3 raises when scope is not staff" do
      scope = %Lanttern.Identity.Scope{profile_type: "student"}
      strand = insert(:strand)

      assert_raise MatchError, fn ->
        Strands.sync_strand_class_assignments(scope, strand.id, [])
      end
    end

    test "sync_strand_class_assignments/3 raises when class_ids contains a class from another school" do
      scope = staff_scope_fixture()
      strand = insert(:strand)
      other_school = insert(:school)
      other_school_class = insert(:class, school: other_school)

      assert_raise MatchError, fn ->
        Strands.sync_strand_class_assignments(scope, strand.id, [other_school_class.id])
      end
    end
  end

  describe "strand lock changesets (schema)" do
    alias Lanttern.LearningContext.Strand

    test "lock_changeset/2 stamps locked_at and keeps locked_by_staff_member_id when locking" do
      changeset =
        Strand.lock_changeset(%Strand{}, %{is_locked: true, locked_by_staff_member_id: 7})

      assert changeset.valid?
      assert get_change(changeset, :is_locked) == true
      assert get_change(changeset, :locked_by_staff_member_id) == 7
      assert %DateTime{} = get_change(changeset, :locked_at)
    end

    test "lock_changeset/2 clears locked_at and locked_by_staff_member_id when unlocking" do
      locked = %Strand{
        is_locked: true,
        locked_at: ~U[2025-01-01 00:00:00Z],
        locked_by_staff_member_id: 7
      }

      changeset = Strand.lock_changeset(locked, %{is_locked: false})

      assert changeset.valid?
      assert get_change(changeset, :is_locked) == false
      assert get_change(changeset, :locked_at) == nil
      assert get_change(changeset, :locked_by_staff_member_id) == nil
    end

    test "lock_changeset/2 requires is_locked" do
      changeset = Strand.lock_changeset(%Strand{is_locked: true}, %{is_locked: nil})

      refute changeset.valid?
      assert %{is_locked: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset/2 does not cast is_locked or its provenance" do
      changeset =
        Strand.changeset(%Strand{}, %{
          name: "n",
          description: "d",
          is_locked: true,
          locked_at: ~U[2025-01-01 00:00:00Z],
          locked_by_staff_member_id: 7
        })

      refute Map.has_key?(changeset.changes, :is_locked)
      refute Map.has_key?(changeset.changes, :locked_at)
      refute Map.has_key?(changeset.changes, :locked_by_staff_member_id)
    end
  end

  describe "lock_strand/2 and unlock_strand/2" do
    alias Lanttern.LearningContext.Strand
    alias Lanttern.LearningContext.StrandLog

    import Lanttern.Factory
    import Lanttern.IdentityFixtures, only: [staff_scope_fixture: 1]

    test "lock_strand/2 locks the strand and stamps provenance for a holder" do
      scope = staff_scope_fixture(permissions: ["strand_lock_management"])
      strand = insert(:strand)

      assert {:ok, %Strand{} = locked} = Strands.lock_strand(scope, strand)
      assert locked.is_locked
      assert %DateTime{} = locked.locked_at
      assert locked.locked_by_staff_member_id == scope.staff_member_id
    end

    test "lock_strand/2 raises for a non-holder" do
      scope = staff_scope_fixture(permissions: [])
      strand = insert(:strand)

      assert_raise MatchError, fn -> Strands.lock_strand(scope, strand) end
    end

    test "lock_strand/2 is idempotent and re-stamps provenance on an already-locked strand" do
      scope = staff_scope_fixture(permissions: ["strand_lock_management"])

      strand =
        insert(:strand,
          is_locked: true,
          locked_at: ~U[2020-01-01 00:00:00Z],
          locked_by_staff_member_id: nil
        )

      assert {:ok, %Strand{} = locked} = Strands.lock_strand(scope, strand)
      assert locked.is_locked
      assert DateTime.compare(locked.locked_at, ~U[2020-01-01 00:00:00Z]) == :gt
      assert locked.locked_by_staff_member_id == scope.staff_member_id
    end

    test "lock_strand/2 writes a StrandLog UPDATE row" do
      scope = staff_scope_fixture(permissions: ["strand_lock_management"])
      strand = insert(:strand)

      assert {:ok, _} = Strands.lock_strand(scope, strand)

      assert [%StrandLog{} = log] = Repo.all(StrandLog)
      assert log.operation == "UPDATE"
      assert log.strand_id == strand.id
      assert log.profile_id == scope.profile_id
      assert log.is_locked == true
    end

    test "unlock_strand/2 unlocks and clears provenance for a holder" do
      scope = staff_scope_fixture(permissions: ["strand_lock_management"])

      strand =
        insert(:strand,
          is_locked: true,
          locked_at: ~U[2025-01-01 00:00:00Z],
          locked_by_staff_member_id: scope.staff_member_id
        )

      assert {:ok, %Strand{} = unlocked} = Strands.unlock_strand(scope, strand)
      refute unlocked.is_locked
      assert unlocked.locked_at == nil
      assert unlocked.locked_by_staff_member_id == nil
    end

    test "unlock_strand/2 raises for a non-holder" do
      scope = staff_scope_fixture(permissions: [])
      strand = insert(:strand, is_locked: true)

      assert_raise MatchError, fn -> Strands.unlock_strand(scope, strand) end
    end

    test "unlock_strand/2 writes a StrandLog UPDATE row" do
      scope = staff_scope_fixture(permissions: ["strand_lock_management"])
      strand = insert(:strand, is_locked: true)

      assert {:ok, _} = Strands.unlock_strand(scope, strand)

      assert [%StrandLog{} = log] = Repo.all(StrandLog)
      assert log.operation == "UPDATE"
      assert log.strand_id == strand.id
      assert log.profile_id == scope.profile_id
      assert log.is_locked == false
    end
  end

  describe "strand_locked?/1" do
    import Lanttern.Factory

    test "returns true for a locked strand" do
      strand = insert(:strand, is_locked: true)
      assert Strands.strand_locked?(strand.id)
    end

    test "returns false for an unlocked strand" do
      strand = insert(:strand)
      refute Strands.strand_locked?(strand.id)
    end

    test "returns false for a missing strand" do
      refute Strands.strand_locked?(-1)
    end
  end

  describe "ensure_strand_editable!/2" do
    import Lanttern.Factory
    import Lanttern.IdentityFixtures, only: [staff_scope_fixture: 0, staff_scope_fixture: 1]

    test "returns :ok for a nil strand_id" do
      assert :ok = Strands.ensure_strand_editable!(staff_scope_fixture(), nil)
    end

    test "returns :ok for an unlocked strand" do
      strand = insert(:strand)
      assert :ok = Strands.ensure_strand_editable!(staff_scope_fixture(), strand.id)
    end

    test "returns :ok for a locked strand when the scope holds the permission" do
      scope = staff_scope_fixture(permissions: ["strand_lock_management"])
      strand = insert(:strand, is_locked: true)
      assert :ok = Strands.ensure_strand_editable!(scope, strand.id)
    end

    test "raises for a locked strand without the permission" do
      strand = insert(:strand, is_locked: true)

      assert_raise RuntimeError, fn ->
        Strands.ensure_strand_editable!(staff_scope_fixture(), strand.id)
      end
    end
  end

  describe "strand lock — out-of-scope mutations stay editable while locked" do
    import Lanttern.Factory
    import Lanttern.IdentityFixtures, only: [staff_scope_fixture: 0]

    test "strand curriculum items remain editable on a locked strand" do
      scope = staff_scope_fixture()
      strand = insert(:strand, is_locked: true)
      curriculum_item = insert(:curriculum_item)

      assert {:ok, _} =
               Strands.create_strand_curriculum_item(scope, %{
                 position: 1,
                 strand_id: strand.id,
                 curriculum_item_id: curriculum_item.id
               })
    end

    test "class assignments remain editable on a locked strand" do
      scope = staff_scope_fixture()
      school = Repo.get!(Lanttern.Schools.School, scope.school_id)
      strand = insert(:strand, is_locked: true)
      class = insert(:class, school: school)

      assert {:ok, _} =
               Strands.create_strand_class_assignment(scope, %{
                 strand_id: strand.id,
                 class_id: class.id
               })
    end
  end
end
