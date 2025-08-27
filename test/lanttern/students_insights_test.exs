defmodule Lanttern.StudentsInsightsTest do
  use Lanttern.DataCase

  alias Lanttern.StudentsInsights

  describe "students_insights" do
    import Lanttern.Factory

    alias Lanttern.Identity.User
    alias Lanttern.StudentsInsights.StudentInsight

    # Simplified helper using existing factories
    defp create_test_user do
      school = insert(:school)
      staff_member = insert(:staff_member, school: school)

      user = %User{
        current_profile: %{
          school_id: school.id,
          staff_member_id: staff_member.id,
          permissions: ["school_management"]
        }
      }

      {user, school, staff_member}
    end

    defp create_test_user_without_permissions do
      school = insert(:school)
      staff_member = insert(:staff_member, school: school)

      user = %User{
        current_profile: %{
          school_id: school.id,
          staff_member_id: staff_member.id,
          permissions: []
        }
      }

      {user, school, staff_member}
    end

    test "list_student_insights/2 returns all student_insights for current user's school" do
      {current_user, school, staff_member} = create_test_user()

      insight1 = insert(:student_insight, school: school, author: staff_member)
      insight2 = insert(:student_insight, school: school, author: staff_member)

      # Create insight in different school (should not be returned)
      other_school = insert(:school)
      _other_insight = insert(:student_insight, school: other_school)

      assert [%{id: id1}, %{id: id2}] = StudentsInsights.list_student_insights(current_user)
      assert MapSet.new([id1, id2]) == MapSet.new([insight1.id, insight2.id])
    end

    test "list_student_insights/2 with author_id filter returns only insights by specified author" do
      {current_user, school, staff_member} = create_test_user()

      insight = insert(:student_insight, school: school, author: staff_member)

      other_staff_member =
        insert(:staff_member, school: school, name: "Other Staff #{System.unique_integer()}")

      _other_insight = insert(:student_insight, school: school, author: other_staff_member)

      assert [%{id: result_id}] =
               StudentsInsights.list_student_insights(current_user, author_id: staff_member.id)

      assert result_id == insight.id
    end

    test "list_student_insights/2 with preloads option loads associated data" do
      {current_user, school, staff_member} = create_test_user()

      insight = insert(:student_insight, school: school, author: staff_member)

      assert [%{id: result_id, author: %{id: author_id}, school: %{id: school_id}}] =
               StudentsInsights.list_student_insights(current_user, preloads: [:author, :school])

      assert result_id == insight.id
      assert author_id == staff_member.id
      assert school_id == school.id
    end

    test "get_student_insight/3 respects school boundaries" do
      {current_user, school, staff_member} = create_test_user()

      insight = insert(:student_insight, school: school, author: staff_member)
      other_school = insert(:school)
      other_staff_member = insert(:staff_member, school: other_school)
      other_insight = insert(:student_insight, school: other_school, author: other_staff_member)

      assert %{id: result_id} = StudentsInsights.get_student_insight(current_user, insight.id)
      assert result_id == insight.id

      assert StudentsInsights.get_student_insight(current_user, other_insight.id) |> is_nil()
    end

    test "get_student_insight!/3 returns insight or raises for cross-school access" do
      {current_user, school, staff_member} = create_test_user()

      insight = insert(:student_insight, school: school, author: staff_member)
      other_school = insert(:school)
      other_staff_member = insert(:staff_member, school: other_school)
      other_insight = insert(:student_insight, school: other_school, author: other_staff_member)

      assert %{id: result_id} = StudentsInsights.get_student_insight!(current_user, insight.id)
      assert result_id == insight.id

      assert_raise Ecto.NoResultsError, fn ->
        StudentsInsights.get_student_insight!(current_user, other_insight.id)
      end
    end

    test "create_student_insight/2 workflow - valid creation and validation" do
      {current_user, school, _staff_member} = create_test_user()

      student = insert(:student, school: school)
      tag = insert(:student_insight_tag, school: school)

      valid_attrs = %{
        description: "This student learns better with visual learning techniques",
        student_id: student.id,
        tag_id: tag.id
      }

      assert {:ok, %StudentInsight{} = insight} =
               StudentsInsights.create_student_insight(current_user, valid_attrs)

      assert insight.description == "This student learns better with visual learning techniques"
      assert insight.author_id == current_user.current_profile.staff_member_id
      assert insight.school_id == current_user.current_profile.school_id
      assert insight.tag_id == tag.id

      # Test validation failures
      assert {:error, %Ecto.Changeset{}} =
               StudentsInsights.create_student_insight(current_user, %{description: nil})

      long_description = String.duplicate("a", 281)

      assert {:error, %Ecto.Changeset{} = changeset} =
               StudentsInsights.create_student_insight(current_user, %{
                 description: long_description
               })

      assert "Description must be 280 characters or less" in errors_on(changeset).description
    end

    test "update_student_insight/3 workflow - authorization and validation" do
      {current_user, school, staff_member} = create_test_user()

      insight = insert(:student_insight, school: school, author: staff_member)

      other_staff_member =
        insert(:staff_member, school: school, name: "Other Staff #{System.unique_integer()}")

      other_insight = insert(:student_insight, school: school, author: other_staff_member)

      # Test successful update by author
      update_attrs = %{description: "Updated insight about this student's learning patterns"}

      assert {:ok, %StudentInsight{} = updated_insight} =
               StudentsInsights.update_student_insight(current_user, insight, update_attrs)

      assert updated_insight.description ==
               "Updated insight about this student's learning patterns"

      assert updated_insight.id == insight.id

      # Test unauthorized update by non-author
      assert {:error, :unauthorized} =
               StudentsInsights.update_student_insight(current_user, other_insight, update_attrs)

      # Test validation failure
      assert {:error, %Ecto.Changeset{}} =
               StudentsInsights.update_student_insight(current_user, insight, %{description: nil})
    end

    test "delete_student_insight/2 workflow - authorization controls" do
      {current_user, school, staff_member} = create_test_user()

      insight = insert(:student_insight, school: school, author: staff_member)

      other_staff_member =
        insert(:staff_member, school: school, name: "Other Staff #{System.unique_integer()}")

      other_insight = insert(:student_insight, school: school, author: other_staff_member)

      # Test successful deletion by author
      assert {:ok, %StudentInsight{}} =
               StudentsInsights.delete_student_insight(current_user, insight)

      assert_raise Ecto.NoResultsError, fn ->
        StudentsInsights.get_student_insight!(current_user, insight.id)
      end

      # Test unauthorized deletion by non-author
      assert {:error, :unauthorized} =
               StudentsInsights.delete_student_insight(current_user, other_insight)

      assert StudentsInsights.get_student_insight(current_user, other_insight.id)
    end

    test "change_student_insight/2 returns a student_insight changeset" do
      {current_user, school, staff_member} = create_test_user()

      insight = insert(:student_insight, school: school, author: staff_member)

      assert %Ecto.Changeset{} = StudentsInsights.change_student_insight(current_user, insight)
    end

    test "create_student_insight/2 handles string keys from forms" do
      {current_user, school, _staff_member} = create_test_user()

      student = insert(:student, school: school)
      tag = insert(:student_insight_tag, school: school)

      attrs_with_string_keys = %{
        "description" => "Mixed keys test",
        "student_id" => student.id,
        "tag_id" => tag.id
      }

      assert {:ok, %StudentInsight{} = insight} =
               StudentsInsights.create_student_insight(current_user, attrs_with_string_keys)

      assert insight.description == "Mixed keys test"
      assert insight.author_id == current_user.current_profile.staff_member_id
      assert insight.school_id == current_user.current_profile.school_id
      assert insight.tag_id == tag.id
    end

    test "cross-school access protection and empty results" do
      {user1, school1, staff1} = create_test_user()
      {user2, school2, staff2} = create_test_user()

      insight1 = insert(:student_insight, school: school1, author: staff1)
      insight2 = insert(:student_insight, school: school2, author: staff2)

      # Users should only see insights from their own school
      assert [%{id: id1}] = StudentsInsights.list_student_insights(user1)
      assert [%{id: id2}] = StudentsInsights.list_student_insights(user2)
      assert id1 == insight1.id
      assert id2 == insight2.id

      # Cross-school get should return nil
      assert StudentsInsights.get_student_insight(user1, insight2.id) == nil
      assert StudentsInsights.get_student_insight(user2, insight1.id) == nil

      # Test empty results for user with no insights
      {user3, _school3, _staff3} = create_test_user()
      assert StudentsInsights.list_student_insights(user3) == []
    end

    test "insights are ordered by insertion date descending" do
      {current_user, school, staff_member} = create_test_user()

      now = DateTime.utc_now()

      insight1 =
        insert(:student_insight,
          school: school,
          author: staff_member,
          inserted_at: DateTime.add(now, -2, :second)
        )

      insight2 =
        insert(:student_insight,
          school: school,
          author: staff_member,
          inserted_at: DateTime.add(now, -1, :second)
        )

      insight3 = insert(:student_insight, school: school, author: staff_member, inserted_at: now)

      assert [%{id: id1}, %{id: id2}, %{id: id3}] =
               StudentsInsights.list_student_insights(current_user)

      assert [id1, id2, id3] == [insight3.id, insight2.id, insight1.id]
    end

    test "create_student_insight/2 with student relationship" do
      {current_user, school, _staff_member} = create_test_user()

      student = insert(:student, school: school)
      tag = insert(:student_insight_tag, school: school)

      attrs = %{
        description: "Great insight about this student",
        student_id: student.id,
        tag_id: tag.id
      }

      assert {:ok, %StudentInsight{} = insight} =
               StudentsInsights.create_student_insight(current_user, attrs)

      insight_with_student = Lanttern.Repo.preload(insight, :student)

      assert insight.description == "Great insight about this student"
      assert insight_with_student.student.id == student.id
    end

    test "create_student_insight/2 student validation failures" do
      {current_user, _school, _staff_member} = create_test_user()

      other_school = insert(:school)
      student_other_school = insert(:student, school: other_school)

      # Test cross-school student rejection
      assert {:error, %Ecto.Changeset{} = changeset} =
               StudentsInsights.create_student_insight(current_user, %{
                 description: "This should fail",
                 student_id: student_other_school.id
               })

      assert "student is invalid or from different school" in errors_on(changeset).student_id

      # Test missing student_id
      assert {:error, %Ecto.Changeset{} = changeset} =
               StudentsInsights.create_student_insight(current_user, %{
                 description: "This should fail without student"
               })

      assert "can't be blank" in errors_on(changeset).student_id

      # Test nil student_id
      assert {:error, %Ecto.Changeset{} = changeset} =
               StudentsInsights.create_student_insight(current_user, %{
                 description: "This should fail",
                 student_id: nil
               })

      assert "student is required" in errors_on(changeset).student_id
    end

    test "update_student_insight/3 student relationship updates" do
      {current_user, school, staff_member} = create_test_user()

      student1 = insert(:student, school: school, name: "Student 1 #{System.unique_integer()}")
      student2 = insert(:student, school: school, name: "Student 2 #{System.unique_integer()}")
      insight = insert(:student_insight, school: school, author: staff_member, student: student1)

      # Test successful student update
      update_attrs = %{description: "Updated description", student_id: student2.id}

      assert {:ok, %StudentInsight{} = updated_insight} =
               StudentsInsights.update_student_insight(current_user, insight, update_attrs)

      updated_insight_with_student = Lanttern.Repo.preload(updated_insight, :student)
      assert updated_insight.description == "Updated description"
      assert updated_insight_with_student.student.id == student2.id

      # Test cross-school student rejection
      other_school = insert(:school)

      student_other_school =
        insert(:student, school: other_school, name: "Other Student #{System.unique_integer()}")

      assert {:error, %Ecto.Changeset{} = changeset} =
               StudentsInsights.update_student_insight(current_user, insight, %{
                 student_id: student_other_school.id
               })

      assert "student is invalid or from different school" in errors_on(changeset).student_id
    end
  end

  describe "tags" do
    import Lanttern.Factory

    alias Lanttern.StudentsInsights.Tag

    test "list_tags/2 returns school tags ordered by name with preloads" do
      {current_user, school, _staff_member} = create_test_user()

      _tag1 = insert(:student_insight_tag, school: school, name: "Urgent")
      tag2 = insert(:student_insight_tag, school: school, name: "Important")

      # Create tag in different school (should not be returned)
      other_school = insert(:school)
      _other_tag = insert(:student_insight_tag, school: other_school, name: "Other")

      # Test basic listing
      assert [%{name: "Important"}, %{name: "Urgent"}] = StudentsInsights.list_tags(current_user)

      # Test preloads - get first tag with preload
      tags_with_preload = StudentsInsights.list_tags(current_user, preloads: [:school])
      assert [%{id: result_id, school: %{id: school_id}} | _] = tags_with_preload
      assert result_id == tag2.id
      assert school_id == school.id
    end

    test "get_tag/3 respects school boundaries and supports preloads" do
      {current_user, school, _staff_member} = create_test_user()

      tag = insert(:student_insight_tag, school: school, name: "Test Tag")
      other_school = insert(:school)
      other_tag = insert(:student_insight_tag, school: other_school, name: "Other Tag")

      # Test successful get
      assert %{id: result_id, name: "Test Tag"} = StudentsInsights.get_tag(current_user, tag.id)
      assert result_id == tag.id

      # Test cross-school access blocked
      assert StudentsInsights.get_tag(current_user, other_tag.id) |> is_nil()

      # Test preloads
      assert %{id: result_id, school: %{id: school_id}} =
               StudentsInsights.get_tag(current_user, tag.id, preloads: [:school])

      assert result_id == tag.id
      assert school_id == school.id
    end

    test "get_tag!/3 returns tag or raises for cross-school access" do
      {current_user, school, _staff_member} = create_test_user()

      tag = insert(:student_insight_tag, school: school, name: "Test Tag")
      other_school = insert(:school)
      other_tag = insert(:student_insight_tag, school: other_school, name: "Other Tag")

      assert %{id: result_id, name: "Test Tag"} = StudentsInsights.get_tag!(current_user, tag.id)
      assert result_id == tag.id

      assert_raise Ecto.NoResultsError, fn ->
        StudentsInsights.get_tag!(current_user, other_tag.id)
      end
    end

    test "create_tag/2 workflow - creation and validation" do
      {current_user, _school, _staff_member} = create_test_user()

      # Test successful creation
      valid_attrs = %{
        name: "Important",
        description: "This is an important tag for testing",
        bg_color: "#ff0000",
        text_color: "#ffffff"
      }

      assert {:ok, %Tag{} = tag} = StudentsInsights.create_tag(current_user, valid_attrs)
      assert tag.name == "Important"
      assert tag.description == "This is an important tag for testing"
      assert tag.bg_color == "#ff0000"
      assert tag.text_color == "#ffffff"
      assert tag.school_id == current_user.current_profile.school_id

      # Test string keys support
      attrs_with_string_keys = %{
        "name" => "String Keys Tag",
        "description" => "String keys description test",
        "bg_color" => "#00ff00",
        "text_color" => "#000000"
      }

      assert {:ok, %Tag{} = tag2} =
               StudentsInsights.create_tag(current_user, attrs_with_string_keys)

      assert tag2.name == "String Keys Tag"
      assert tag2.description == "String keys description test"
      assert tag2.bg_color == "#00ff00"
      assert tag2.text_color == "#000000"
      assert tag2.school_id == current_user.current_profile.school_id

      # Test creating tag without description (optional field)
      attrs_without_description = %{
        name: "No Description Tag",
        bg_color: "#0000ff",
        text_color: "#ffffff"
      }

      assert {:ok, %Tag{} = tag3} =
               StudentsInsights.create_tag(current_user, attrs_without_description)

      assert tag3.name == "No Description Tag"
      assert tag3.description == nil
      assert tag3.bg_color == "#0000ff"
      assert tag3.text_color == "#ffffff"

      # Test validation failure
      assert {:error, %Ecto.Changeset{}} =
               StudentsInsights.create_tag(current_user, %{name: nil})
    end

    test "create_tag/2 requires school_management permission" do
      {unauthorized_user, _school, _staff_member} = create_test_user_without_permissions()

      valid_attrs = %{
        name: "Should Fail",
        bg_color: "#ff0000",
        text_color: "#ffffff"
      }

      assert {:error, :unauthorized} = StudentsInsights.create_tag(unauthorized_user, valid_attrs)
    end

    test "update_tag/3 workflow - authorization and validation" do
      {current_user, school, _staff_member} = create_test_user()

      tag = insert(:student_insight_tag, school: school, name: "Original Name")
      other_school = insert(:school)
      other_tag = insert(:student_insight_tag, school: other_school, name: "Other Tag")

      # Test successful update
      update_attrs = %{
        name: "Updated Name",
        description: "Updated description",
        bg_color: "#0000ff"
      }

      assert {:ok, %Tag{} = updated_tag} =
               StudentsInsights.update_tag(current_user, tag, update_attrs)

      assert updated_tag.name == "Updated Name"
      assert updated_tag.description == "Updated description"
      assert updated_tag.bg_color == "#0000ff"
      assert updated_tag.id == tag.id

      # Test unauthorized update
      assert {:error, :unauthorized} =
               StudentsInsights.update_tag(current_user, other_tag, %{name: "Trying to update"})

      # Test validation failure
      assert {:error, %Ecto.Changeset{}} =
               StudentsInsights.update_tag(current_user, tag, %{name: nil})
    end

    test "update_tag/3 requires school_management permission" do
      {_authorized_user, school, _staff_member} = create_test_user()
      {unauthorized_user, _other_school, _other_staff} = create_test_user_without_permissions()

      # Create tag with authorized user
      tag = insert(:student_insight_tag, school: school, name: "Test Tag")

      update_attrs = %{name: "Should Fail"}

      assert {:error, :unauthorized} =
               StudentsInsights.update_tag(unauthorized_user, tag, update_attrs)
    end

    test "delete_tag/2 workflow - authorization controls" do
      {current_user, school, _staff_member} = create_test_user()

      tag = insert(:student_insight_tag, school: school, name: "Tag to Delete")
      other_school = insert(:school)
      other_tag = insert(:student_insight_tag, school: other_school, name: "Other Tag")

      # Test successful deletion
      assert {:ok, %Tag{}} = StudentsInsights.delete_tag(current_user, tag)

      assert_raise Ecto.NoResultsError, fn ->
        StudentsInsights.get_tag!(current_user, tag.id)
      end

      # Test unauthorized deletion
      assert {:error, :unauthorized} = StudentsInsights.delete_tag(current_user, other_tag)
      assert Lanttern.Repo.get(Tag, other_tag.id) != nil
    end

    test "delete_tag/2 requires school_management permission" do
      {_authorized_user, school, _staff_member} = create_test_user()
      {unauthorized_user, _other_school, _other_staff} = create_test_user_without_permissions()

      # Create tag with authorized user
      tag = insert(:student_insight_tag, school: school, name: "Test Tag")

      assert {:error, :unauthorized} = StudentsInsights.delete_tag(unauthorized_user, tag)

      # Verify tag still exists
      assert Lanttern.Repo.get(Tag, tag.id) != nil
    end

    test "change_tag/3 returns changeset with optional attributes" do
      {current_user, school, _staff_member} = create_test_user()

      tag = insert(:student_insight_tag, school: school, name: "Test Tag")

      assert %Ecto.Changeset{} = StudentsInsights.change_tag(current_user, tag)

      changeset =
        StudentsInsights.change_tag(current_user, tag, %{
          name: "Changed Name",
          description: "Changed description"
        })

      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.name == "Changed Name"
      assert changeset.changes.description == "Changed description"
    end

    test "tags cross-school protection, ordering and empty results" do
      {user1, school1, _staff1} = create_test_user()
      {user2, school2, _staff2} = create_test_user()

      tag1 = insert(:student_insight_tag, school: school1, name: "School 1 Tag")
      tag2 = insert(:student_insight_tag, school: school2, name: "School 2 Tag")

      # Test cross-school access protection
      assert [%{id: id1}] = StudentsInsights.list_tags(user1)
      assert [%{id: id2}] = StudentsInsights.list_tags(user2)
      assert id1 == tag1.id
      assert id2 == tag2.id
      assert StudentsInsights.get_tag(user1, tag2.id) == nil
      assert StudentsInsights.get_tag(user2, tag1.id) == nil

      # Test ordering and empty results
      {user3, school3, _staff3} = create_test_user()
      assert StudentsInsights.list_tags(user3) == []

      # Test alphabetical ordering
      insert(:student_insight_tag, school: school3, name: "Zebra")
      insert(:student_insight_tag, school: school3, name: "Alpha")
      insert(:student_insight_tag, school: school3, name: "Bravo")

      assert [%{name: "Alpha"}, %{name: "Bravo"}, %{name: "Zebra"}] =
               StudentsInsights.list_tags(user3)
    end
  end
end
