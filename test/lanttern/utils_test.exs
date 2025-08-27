defmodule Lanttern.UtilsTest do
  use ExUnit.Case, async: true

  alias Lanttern.Identity.User
  alias Lanttern.Utils

  describe "normalize_attrs_to_atom_keys/1" do
    test "converts string keys to atom keys" do
      attrs = %{"name" => "John", "age" => 30, "active" => true}
      expected = %{name: "John", age: 30, active: true}

      assert Utils.normalize_attrs_to_atom_keys(attrs) == expected
    end

    test "leaves atom keys unchanged" do
      attrs = %{name: "John", age: 30, active: true}
      expected = %{name: "John", age: 30, active: true}

      assert Utils.normalize_attrs_to_atom_keys(attrs) == expected
    end

    test "handles mixed string and atom keys" do
      attrs = %{"name" => "John", :age => 30, "active" => true}
      expected = %{name: "John", age: 30, active: true}

      assert Utils.normalize_attrs_to_atom_keys(attrs) == expected
    end

    test "handles empty map" do
      attrs = %{}
      expected = %{}

      assert Utils.normalize_attrs_to_atom_keys(attrs) == expected
    end

    test "leaves non-string, non-atom keys unchanged" do
      attrs = %{"name" => "John", 123 => "number key", {:tuple, "key"} => "tuple key"}
      expected = %{:name => "John", 123 => "number key", {:tuple, "key"} => "tuple key"}

      assert Utils.normalize_attrs_to_atom_keys(attrs) == expected
    end

    test "handles nested structures (does not convert nested keys)" do
      attrs = %{
        "user" => %{"name" => "John", "settings" => %{"theme" => "dark"}},
        "tags" => ["tag1", "tag2"]
      }

      expected = %{
        :user => %{"name" => "John", "settings" => %{"theme" => "dark"}},
        :tags => ["tag1", "tag2"]
      }

      assert Utils.normalize_attrs_to_atom_keys(attrs) == expected
    end

    test "handles nil and special values" do
      attrs = %{"name" => nil, "count" => 0, "active" => false, "data" => ""}
      expected = %{name: nil, count: 0, active: false, data: ""}

      assert Utils.normalize_attrs_to_atom_keys(attrs) == expected
    end
  end

  describe "check_permission/2" do
    test "returns :ok when user has the required permission" do
      user = %User{current_profile: %{permissions: ["school_management", "other_permission"]}}

      assert Utils.check_permission(user, "school_management") == :ok
    end

    test "returns {:error, :unauthorized} when user does not have the required permission" do
      user = %User{current_profile: %{permissions: ["other_permission"]}}

      assert Utils.check_permission(user, "school_management") == {:error, :unauthorized}
    end

    test "returns {:error, :unauthorized} when user has no permissions" do
      user = %User{current_profile: %{permissions: []}}

      assert Utils.check_permission(user, "school_management") == {:error, :unauthorized}
    end

    test "is case sensitive for permission names" do
      user = %User{current_profile: %{permissions: ["School_Management"]}}

      assert Utils.check_permission(user, "school_management") == {:error, :unauthorized}
    end
  end
end
