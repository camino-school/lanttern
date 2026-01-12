defmodule Lanttern.LessonTemplatesTest do
  use Lanttern.DataCase

  alias Lanttern.LessonTemplates
  alias Lanttern.LessonTemplates.LessonTemplate

  import Lanttern.Factory

  describe "lesson_templates" do
    alias Lanttern.IdentityFixtures
    alias Lanttern.Schools.School

    @invalid_attrs %{name: nil, template: nil, about: nil}

    test "list_lesson_templates/1 returns all lesson_templates from scope's school ordered by name" do
      scope = IdentityFixtures.scope_fixture()
      school = Repo.get!(School, scope.school_id)

      # Insert lesson templates for the scope's school
      lesson_template_c = insert(:lesson_template, %{name: "Charlie Template", school: school})
      lesson_template_a = insert(:lesson_template, %{name: "Alpha Template", school: school})
      lesson_template_b = insert(:lesson_template, %{name: "Bravo Template", school: school})

      # Create lesson template from different school to verify filtering
      other_school = insert(:school)
      insert(:lesson_template, %{name: "Other School Template", school: other_school})

      lesson_templates = LessonTemplates.list_lesson_templates(scope)

      assert [lesson_template_a.id, lesson_template_b.id, lesson_template_c.id] ==
               Enum.map(lesson_templates, & &1.id)
    end

    test "get_lesson_template!/2 returns the lesson_template with given id from scope's school" do
      scope = IdentityFixtures.scope_fixture()
      school = Repo.get!(School, scope.school_id)
      lesson_template = insert(:lesson_template, %{school: school})

      expected_lesson_template = LessonTemplates.get_lesson_template!(scope, lesson_template.id)

      assert expected_lesson_template.id == lesson_template.id
      assert expected_lesson_template.name == lesson_template.name
      assert expected_lesson_template.school_id == lesson_template.school_id
    end

    test "create_lesson_template/2 with valid data creates a lesson_template" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})

      valid_attrs = %{
        name: "some name",
        template: "some template",
        about: "some about"
      }

      assert {:ok, %LessonTemplate{} = lesson_template} =
               LessonTemplates.create_lesson_template(scope, valid_attrs)

      assert lesson_template.name == "some name"
      assert lesson_template.template == "some template"
      assert lesson_template.about == "some about"
      assert lesson_template.school_id == scope.school_id
    end

    test "create_lesson_template/2 with invalid data returns error changeset" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})

      assert {:error, %Ecto.Changeset{}} =
               LessonTemplates.create_lesson_template(scope, @invalid_attrs)
    end

    test "update_lesson_template/3 with valid data updates the lesson_template" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
      school = Repo.get!(School, scope.school_id)
      lesson_template = insert(:lesson_template, %{school: school})

      update_attrs = %{
        name: "some updated name",
        template: "some updated template",
        about: "some updated about"
      }

      assert {:ok, %LessonTemplate{} = updated_lesson_template} =
               LessonTemplates.update_lesson_template(scope, lesson_template, update_attrs)

      assert updated_lesson_template.name == "some updated name"
      assert updated_lesson_template.template == "some updated template"
      assert updated_lesson_template.about == "some updated about"
      assert updated_lesson_template.school_id == scope.school_id
    end

    test "update_lesson_template/3 with invalid data returns error changeset" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
      school = Repo.get!(School, scope.school_id)
      lesson_template = insert(:lesson_template, %{school: school})

      assert {:error, %Ecto.Changeset{}} =
               LessonTemplates.update_lesson_template(scope, lesson_template, @invalid_attrs)

      expected_lesson_template = LessonTemplates.get_lesson_template!(scope, lesson_template.id)
      assert expected_lesson_template.id == lesson_template.id
      assert expected_lesson_template.name == lesson_template.name
    end

    test "delete_lesson_template/2 deletes the lesson_template" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
      school = Repo.get!(School, scope.school_id)
      lesson_template = insert(:lesson_template, %{school: school})

      assert {:ok, %LessonTemplate{}} =
               LessonTemplates.delete_lesson_template(scope, lesson_template)

      assert_raise Ecto.NoResultsError, fn ->
        LessonTemplates.get_lesson_template!(scope, lesson_template.id)
      end
    end

    test "change_lesson_template/2 returns a lesson_template changeset" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
      school = Repo.get!(School, scope.school_id)
      lesson_template = insert(:lesson_template, %{school: school})

      assert %Ecto.Changeset{} = LessonTemplates.change_lesson_template(scope, lesson_template)
    end
  end

  describe "permission checks" do
    alias Lanttern.IdentityFixtures
    alias Lanttern.Schools.School

    test "create_lesson_template/2 fails when user lacks content_management permission" do
      scope = IdentityFixtures.scope_fixture(%{permissions: []})

      valid_attrs = %{name: "Test Template"}

      assert_raise MatchError, fn ->
        LessonTemplates.create_lesson_template(scope, valid_attrs)
      end
    end

    test "update_lesson_template/3 fails when user lacks content_management permission" do
      scope = IdentityFixtures.scope_fixture(%{permissions: []})
      school = Repo.get!(School, scope.school_id)
      lesson_template = insert(:lesson_template, %{school: school})

      assert_raise MatchError, fn ->
        LessonTemplates.update_lesson_template(scope, lesson_template, %{name: "Updated"})
      end
    end

    test "delete_lesson_template/2 fails when user lacks content_management permission" do
      scope = IdentityFixtures.scope_fixture(%{permissions: []})
      school = Repo.get!(School, scope.school_id)
      lesson_template = insert(:lesson_template, %{school: school})

      assert_raise MatchError, fn ->
        LessonTemplates.delete_lesson_template(scope, lesson_template)
      end
    end

    test "change_lesson_template/2 fails when user lacks content_management permission" do
      scope = IdentityFixtures.scope_fixture(%{permissions: []})
      school = Repo.get!(School, scope.school_id)
      lesson_template = insert(:lesson_template, %{school: school})

      assert_raise MatchError, fn ->
        LessonTemplates.change_lesson_template(scope, lesson_template)
      end
    end
  end

  describe "school isolation" do
    alias Lanttern.IdentityFixtures

    test "get_lesson_template!/2 fails when lesson_template belongs to different school" do
      scope = IdentityFixtures.scope_fixture()
      other_school = insert(:school)
      lesson_template = insert(:lesson_template, school: other_school)

      assert_raise Ecto.NoResultsError, fn ->
        LessonTemplates.get_lesson_template!(scope, lesson_template.id)
      end
    end

    test "update_lesson_template/3 fails when lesson_template belongs to different school" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
      other_school = insert(:school)
      lesson_template = insert(:lesson_template, school: other_school)

      assert_raise MatchError, fn ->
        LessonTemplates.update_lesson_template(scope, lesson_template, %{name: "Updated"})
      end
    end

    test "delete_lesson_template/2 fails when lesson_template belongs to different school" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
      other_school = insert(:school)
      lesson_template = insert(:lesson_template, school: other_school)

      assert_raise MatchError, fn ->
        LessonTemplates.delete_lesson_template(scope, lesson_template)
      end
    end

    test "change_lesson_template/2 fails when lesson_template belongs to different school" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
      other_school = insert(:school)
      lesson_template = insert(:lesson_template, school: other_school)

      assert_raise MatchError, fn ->
        LessonTemplates.change_lesson_template(scope, lesson_template)
      end
    end
  end
end
