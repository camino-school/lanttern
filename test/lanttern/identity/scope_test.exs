defmodule Lanttern.Identity.ScopeTest do
  use Lanttern.DataCase

  alias Lanttern.Identity.Scope

  import Lanttern.IdentityFixtures

  describe "for_user/1" do
    test "creates a scope from a user with profile" do
      user = current_staff_member_user_fixture(%{}, ["manage_posts"])

      scope = Scope.for_user(user)

      assert %Scope{} = scope
      assert scope.user_id == user.id
      assert scope.profile_id == user.current_profile.id
      assert scope.school_id == user.current_profile.school_id
      assert scope.permissions == ["manage_posts"]
      assert scope.profile_type == "staff"
    end

    test "creates a scope from a user without profile" do
      user = user_fixture()

      scope = Scope.for_user(user)

      assert %Scope{} = scope
      assert scope.user_id == user.id
      assert scope.profile_id == nil
      assert scope.school_id == nil
      assert scope.permissions == []
      assert scope.profile_type == nil
    end

    test "returns nil for nil user" do
      assert Scope.for_user(nil) == nil
    end
  end

  describe "has_permission?/2" do
    test "returns true when scope has the permission" do
      scope = staff_scope_fixture(%{permissions: ["manage_posts", "view_stats"]})

      assert Scope.has_permission?(scope, "manage_posts")
      assert Scope.has_permission?(scope, "view_stats")
    end

    test "returns false when scope does not have the permission" do
      scope = staff_scope_fixture(%{permissions: ["manage_posts"]})

      refute Scope.has_permission?(scope, "view_stats")
    end

    test "returns false for nil scope" do
      refute Scope.has_permission?(nil, "manage_posts")
    end
  end

  describe "belongs_to_school?/2" do
    test "returns true when scope belongs to the school" do
      scope = staff_scope_fixture()

      assert Scope.belongs_to_school?(scope, scope.school_id)
    end

    test "returns false when scope does not belong to the school" do
      scope = staff_scope_fixture()

      refute Scope.belongs_to_school?(scope, scope.school_id + 1)
    end

    test "returns false for nil scope" do
      refute Scope.belongs_to_school?(nil, 1)
    end
  end

  describe "profile_type?/2" do
    test "returns true for matching profile type" do
      staff_scope = staff_scope_fixture()
      student_scope = student_scope_fixture()
      guardian_scope = guardian_scope_fixture()

      assert Scope.profile_type?(staff_scope, "staff")
      assert Scope.profile_type?(student_scope, "student")
      assert Scope.profile_type?(guardian_scope, "guardian")
    end

    test "returns false for non-matching profile type" do
      scope = staff_scope_fixture()

      refute Scope.profile_type?(scope, "student")
      refute Scope.profile_type?(scope, "guardian")
    end

    test "returns false for nil scope" do
      refute Scope.profile_type?(nil, "staff")
    end
  end

  describe "staff_member?/2" do
    test "returns true when scope is staff and staff_member_id matches" do
      scope = staff_scope_fixture()

      assert Scope.staff_member?(scope, scope.staff_member_id)
    end

    test "returns false when scope is staff but staff_member_id doesn't match" do
      scope = staff_scope_fixture()

      refute Scope.staff_member?(scope, scope.staff_member_id + 1)
    end

    test "returns false when profile_type is not staff even if staff_member_id matches" do
      student_scope = student_scope_fixture()

      refute Scope.staff_member?(student_scope, student_scope.staff_member_id)
    end

    test "returns false for nil scope" do
      refute Scope.staff_member?(nil, 1)
    end
  end
end
