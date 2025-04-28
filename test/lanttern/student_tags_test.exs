defmodule Lanttern.StudentTagsTest do
  use Lanttern.DataCase

  alias Lanttern.StudentTags

  describe "student_tags" do
    alias Lanttern.StudentTags.Tag

    import Lanttern.SchoolsFixtures
    import Lanttern.StudentTagsFixtures

    @invalid_attrs %{name: nil, bg_color: nil, text_color: nil, school_id: nil}

    test "list_student_tags/0 returns all student_tags" do
      tag = student_tag_fixture()
      assert StudentTags.list_student_tags() == [tag]
    end

    test "list_student_tags/1 with school_id returns school's student_tags" do
      school = school_fixture()
      tag = student_tag_fixture(%{school_id: school.id})
      _other_tag = student_tag_fixture()

      assert StudentTags.list_student_tags(school_id: school.id) == [tag]
    end

    test "get_student_tag!/1 returns the student_tag with given id" do
      tag = student_tag_fixture()
      assert StudentTags.get_student_tag!(tag.id) == tag
    end

    test "create_student_tag/1 with valid data creates a student_tag" do
      school = school_fixture()

      valid_attrs = %{
        name: "some name",
        bg_color: "#000000",
        text_color: "#ffffff",
        school_id: school.id
      }

      assert {:ok, %Tag{} = tag} = StudentTags.create_student_tag(valid_attrs)
      assert tag.name == "some name"
      assert tag.bg_color == "#000000"
      assert tag.text_color == "#ffffff"
      assert tag.school_id == school.id
    end

    test "create_student_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = StudentTags.create_student_tag(@invalid_attrs)
    end

    test "update_student_tag/2 with valid data updates the student_tag" do
      tag = student_tag_fixture()
      update_attrs = %{name: "some updated name", bg_color: "#111111", text_color: "#eeeeee"}

      assert {:ok, %Tag{} = tag} = StudentTags.update_student_tag(tag, update_attrs)
      assert tag.name == "some updated name"
      assert tag.bg_color == "#111111"
      assert tag.text_color == "#eeeeee"
    end

    test "update_student_tag/2 with invalid data returns error changeset" do
      tag = student_tag_fixture()
      assert {:error, %Ecto.Changeset{}} = StudentTags.update_student_tag(tag, @invalid_attrs)
      assert tag == StudentTags.get_student_tag!(tag.id)
    end

    test "delete_student_tag/1 deletes the student_tag" do
      tag = student_tag_fixture()
      assert {:ok, %Tag{}} = StudentTags.delete_student_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> StudentTags.get_student_tag!(tag.id) end
    end

    test "change_student_tag/1 returns a student_tag changeset" do
      tag = student_tag_fixture()
      assert %Ecto.Changeset{} = StudentTags.change_student_tag(tag)
    end

    test "update_student_tags_positions/1 updates positions" do
      tag1 = student_tag_fixture(%{position: 0})
      tag2 = student_tag_fixture(%{position: 1})
      tag3 = student_tag_fixture(%{position: 2})

      assert :ok = StudentTags.update_student_tags_positions([tag3.id, tag1.id, tag2.id])

      [updated_tag3, updated_tag1, updated_tag2] = StudentTags.list_student_tags()
      assert updated_tag3.id == tag3.id
      assert updated_tag3.position == 0
      assert updated_tag1.id == tag1.id
      assert updated_tag1.position == 1
      assert updated_tag2.id == tag2.id
      assert updated_tag2.position == 2
    end
  end
end
