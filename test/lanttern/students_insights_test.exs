defmodule Lanttern.StudentsInsightsTest do
  use Lanttern.DataCase

  alias Lanttern.StudentsInsights

  describe "students_insights" do
    import Lanttern.Factory

    alias Lanttern.Identity.User
    alias Lanttern.StudentsInsights.StudentInsight

    # Helper function to create a user with properly linked current_profile
    defp create_user_with_profile(attrs \\ %{}) do
      school = insert(:school)
      unique_name = "Staff Member #{System.unique_integer([:positive])}"
      staff_member = insert(:staff_member, school: school, name: unique_name)

      user = %User{
        current_profile: %{
          school_id: school.id,
          staff_member_id: staff_member.id
        }
      }

      # Merge any additional attributes
      user = Map.merge(user, attrs)

      profile =
        insert(:profile,
          type: "staff",
          staff_member: staff_member,
          user: build(:user)
        )

      {user, school, staff_member, profile}
    end

    test "list_student_insights/2 returns all student_insights for current user's school" do
      {current_user, school, staff_member, _profile} = create_user_with_profile()

      # Create insights in the same school
      insight1 = insert(:student_insight, school: school, author: staff_member)
      insight2 = insert(:student_insight, school: school, author: staff_member)

      # Create insight in different school (should not be returned)
      other_school = insert(:school)
      _other_insight = insert(:student_insight, school: other_school)

      results = StudentsInsights.list_student_insights(current_user)

      assert length(results) == 2
      ids = Enum.map(results, & &1.id)
      assert insight1.id in ids
      assert insight2.id in ids
    end

    test "list_student_insights/2 with author_id filter returns only insights by specified author" do
      {current_user, school, staff_member, _profile} = create_user_with_profile()

      # Create insights by current staff member
      insight = insert(:student_insight, school: school, author: staff_member)

      # Create insight by other staff member in same school
      other_staff_member =
        insert(:staff_member,
          school: school,
          name: "Other Staff #{System.unique_integer([:positive])}"
        )

      _other_insight = insert(:student_insight, school: school, author: other_staff_member)

      [result] = StudentsInsights.list_student_insights(current_user, author_id: staff_member.id)

      assert result.id == insight.id
    end

    test "list_student_insights/2 with preloads option loads associated data" do
      {current_user, school, staff_member, _profile} = create_user_with_profile()

      insight = insert(:student_insight, school: school, author: staff_member)

      [result] =
        StudentsInsights.list_student_insights(current_user, preloads: [:author, :school])

      assert result.id == insight.id
      assert result.author.id == staff_member.id
      assert result.school.id == school.id
    end

    test "get_student_insight/3 returns the insight when it belongs to user's school" do
      {current_user, school, staff_member, _profile} = create_user_with_profile()

      insight = insert(:student_insight, school: school, author: staff_member)

      result = StudentsInsights.get_student_insight(current_user, insight.id)

      assert result.id == insight.id
    end

    test "get_student_insight/3 returns nil when insight belongs to different school" do
      {current_user, _school, _staff_member, _profile} = create_user_with_profile()

      # Create insight in different school
      other_school = insert(:school)

      other_staff_member =
        insert(:staff_member,
          school: other_school,
          name: "Cross School Staff #{System.unique_integer([:positive])}"
        )

      other_insight = insert(:student_insight, school: other_school, author: other_staff_member)

      assert StudentsInsights.get_student_insight(current_user, other_insight.id) |> is_nil()
    end

    test "get_student_insight!/3 returns the insight when it belongs to user's school" do
      {current_user, school, staff_member, _profile} = create_user_with_profile()

      insight = insert(:student_insight, school: school, author: staff_member)

      result = StudentsInsights.get_student_insight!(current_user, insight.id)

      assert result.id == insight.id
    end

    test "get_student_insight!/3 raises when insight belongs to different school" do
      {current_user, _school, _staff_member, _profile} = create_user_with_profile()

      # Create insight in different school
      other_school = insert(:school)

      other_staff_member =
        insert(:staff_member,
          school: other_school,
          name: "Different School Staff #{System.unique_integer([:positive])}"
        )

      other_insight = insert(:student_insight, school: other_school, author: other_staff_member)

      assert_raise Ecto.NoResultsError, fn ->
        StudentsInsights.get_student_insight!(current_user, other_insight.id)
      end
    end

    test "create_student_insight/2 with valid data creates a student_insight with current user as author" do
      {current_user, school, _staff_member, _profile} = create_user_with_profile()

      student =
        insert(:student,
          school: school,
          name: "Valid Test Student #{System.unique_integer([:positive])}"
        )

      valid_attrs = %{
        description: "This student learns better with visual learning techniques",
        student_id: student.id
      }

      assert {:ok, %StudentInsight{} = insight} =
               StudentsInsights.create_student_insight(current_user, valid_attrs)

      assert insight.description == "This student learns better with visual learning techniques"
      assert insight.author_id == current_user.current_profile.staff_member_id
      assert insight.school_id == current_user.current_profile.school_id
    end

    test "create_student_insight/2 with invalid data returns error changeset" do
      {current_user, _school, _staff_member, _profile} = create_user_with_profile()

      invalid_attrs = %{description: nil}

      assert {:error, %Ecto.Changeset{}} =
               StudentsInsights.create_student_insight(current_user, invalid_attrs)
    end

    test "create_student_insight/2 validates description length limit" do
      {current_user, _school, _staff_member, _profile} = create_user_with_profile()

      # Create description longer than 280 characters
      long_description = String.duplicate("a", 281)
      invalid_attrs = %{description: long_description}

      assert {:error, %Ecto.Changeset{} = changeset} =
               StudentsInsights.create_student_insight(current_user, invalid_attrs)

      assert "Description must be 280 characters or less" in errors_on(changeset).description
    end

    test "update_student_insight/3 with valid data updates the insight when user is the author" do
      {current_user, school, staff_member, _profile} = create_user_with_profile()

      insight = insert(:student_insight, school: school, author: staff_member)

      update_attrs = %{description: "Updated insight about this student's learning patterns"}

      assert {:ok, %StudentInsight{} = updated_insight} =
               StudentsInsights.update_student_insight(current_user, insight, update_attrs)

      assert updated_insight.description ==
               "Updated insight about this student's learning patterns"

      assert updated_insight.id == insight.id
    end

    test "update_student_insight/3 returns unauthorized when user is not the author" do
      {current_user, school, _staff_member, _profile} = create_user_with_profile()

      # Create insight by different staff member
      other_staff_member =
        insert(:staff_member,
          school: school,
          name: "Different Staff #{System.unique_integer([:positive])}"
        )

      insight = insert(:student_insight, school: school, author: other_staff_member)

      update_attrs = %{description: "Trying to update someone else's insight"}

      assert {:error, :unauthorized} =
               StudentsInsights.update_student_insight(current_user, insight, update_attrs)
    end

    test "update_student_insight/3 with invalid data returns error changeset" do
      {current_user, school, staff_member, _profile} = create_user_with_profile()

      insight = insert(:student_insight, school: school, author: staff_member)

      # Try to set description to nil
      invalid_attrs = %{description: nil}

      assert {:error, %Ecto.Changeset{}} =
               StudentsInsights.update_student_insight(current_user, insight, invalid_attrs)
    end

    test "delete_student_insight/2 deletes the insight when user is the author" do
      {current_user, school, staff_member, _profile} = create_user_with_profile()

      insight = insert(:student_insight, school: school, author: staff_member)

      assert {:ok, %StudentInsight{}} =
               StudentsInsights.delete_student_insight(current_user, insight)

      assert_raise Ecto.NoResultsError, fn ->
        StudentsInsights.get_student_insight!(current_user, insight.id)
      end
    end

    test "delete_student_insight/2 returns unauthorized when user is not the author" do
      {current_user, school, _staff_member, _profile} = create_user_with_profile()

      # Create insight by different staff member
      other_staff_member =
        insert(:staff_member,
          school: school,
          name: "Another Staff #{System.unique_integer([:positive])}"
        )

      insight = insert(:student_insight, school: school, author: other_staff_member)

      assert {:error, :unauthorized} =
               StudentsInsights.delete_student_insight(current_user, insight)

      # Verify insight still exists
      assert StudentsInsights.get_student_insight(current_user, insight.id)
    end

    test "change_student_insight/2 returns a student_insight changeset" do
      {current_user, school, staff_member, _profile} = create_user_with_profile()

      insight = insert(:student_insight, school: school, author: staff_member)

      assert %Ecto.Changeset{} = StudentsInsights.change_student_insight(current_user, insight)
    end

    test "create_student_insight/2 works with string keys" do
      {current_user, school, _staff_member, _profile} = create_user_with_profile()

      student =
        insert(:student,
          school: school,
          name: "String Keys Student #{System.unique_integer([:positive])}"
        )

      # Use string keys like Phoenix forms would provide
      attrs_with_string_keys = %{
        "description" => "This student learns better with visual learning techniques",
        "student_id" => student.id
      }

      assert {:ok, %StudentInsight{} = insight} =
               StudentsInsights.create_student_insight(current_user, attrs_with_string_keys)

      assert insight.description == "This student learns better with visual learning techniques"
      assert insight.author_id == current_user.current_profile.staff_member_id
      assert insight.school_id == current_user.current_profile.school_id
    end

    test "create_student_insight/2 works with mixed atom and string keys" do
      {current_user, school, _staff_member, _profile} = create_user_with_profile()

      student =
        insert(:student,
          school: school,
          name: "Mixed Keys Student #{System.unique_integer([:positive])}"
        )

      # Mix of atom and string keys
      mixed_attrs = %{
        "description" => "Mixed keys test",
        "student_id" => student.id,
        extra_field: "atom key value"
      }

      assert {:ok, %StudentInsight{} = insight} =
               StudentsInsights.create_student_insight(current_user, mixed_attrs)

      assert insight.description == "Mixed keys test"
      assert insight.author_id == current_user.current_profile.staff_member_id
      assert insight.school_id == current_user.current_profile.school_id
    end

    test "cross-school access protection - users can only access insights from their own school" do
      # Create two separate schools with users
      {user1, school1, staff1, _profile1} = create_user_with_profile()
      {user2, school2, staff2, _profile2} = create_user_with_profile()

      # Create insights in each school
      insight1 = insert(:student_insight, school: school1, author: staff1)
      insight2 = insert(:student_insight, school: school2, author: staff2)

      # User1 should only see insights from school1
      insights_for_user1 = StudentsInsights.list_student_insights(user1)
      assert length(insights_for_user1) == 1
      assert hd(insights_for_user1).id == insight1.id

      # User2 should only see insights from school2
      insights_for_user2 = StudentsInsights.list_student_insights(user2)
      assert length(insights_for_user2) == 1
      assert hd(insights_for_user2).id == insight2.id

      # Cross-school get should return nil
      assert StudentsInsights.get_student_insight(user1, insight2.id) == nil
      assert StudentsInsights.get_student_insight(user2, insight1.id) == nil
    end

    test "empty results when no insights exist for user's school" do
      {current_user, _school, _staff_member, _profile} = create_user_with_profile()

      # Create insight in different school
      other_school = insert(:school)

      other_staff_member =
        insert(:staff_member,
          school: other_school,
          name: "Empty Results Staff #{System.unique_integer([:positive])}"
        )

      _other_insight = insert(:student_insight, school: other_school, author: other_staff_member)

      insights = StudentsInsights.list_student_insights(current_user)

      assert insights == []
    end

    test "insights are ordered by insertion date descending" do
      {current_user, school, staff_member, _profile} = create_user_with_profile()

      # Create insights with explicit timestamps to ensure proper ordering
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

      insights = StudentsInsights.list_student_insights(current_user)

      # Should be ordered newest first
      assert length(insights) == 3
      [first, second, third] = insights
      assert first.id == insight3.id
      assert second.id == insight2.id
      assert third.id == insight1.id
    end

    test "create_student_insight/2 with student_id creates insight with student relationship" do
      {current_user, school, _staff_member, _profile} = create_user_with_profile()

      student1 = insert(:student, school: school, name: "Student 1")

      attrs = %{
        description: "Great insight about this student",
        student_id: student1.id
      }

      assert {:ok, %StudentInsight{} = insight} =
               StudentsInsights.create_student_insight(current_user, attrs)

      insight_with_student = Lanttern.Repo.preload(insight, :student)

      assert insight.description == "Great insight about this student"
      assert insight_with_student.student.id == student1.id
    end

    test "create_student_insight/2 with string student_ids works correctly" do
      {current_user, school, _staff_member, _profile} = create_user_with_profile()

      student =
        insert(:student,
          school: school,
          name: "String Test Student #{System.unique_integer([:positive])}"
        )

      attrs = %{
        "description" => "String keys test",
        "student_id" => student.id
      }

      assert {:ok, %StudentInsight{} = insight} =
               StudentsInsights.create_student_insight(current_user, attrs)

      insight_with_student = Lanttern.Repo.preload(insight, :student)

      assert insight.description == "String keys test"
      assert insight_with_student.student.id == student.id
    end

    test "create_student_insight/2 fails when student_id contains cross-school student" do
      {current_user, _school, _staff_member, _profile} = create_user_with_profile()

      other_school = insert(:school)

      student_other_school =
        insert(:student,
          school: other_school,
          name: "Other School Student #{System.unique_integer([:positive])}"
        )

      attrs = %{
        description: "This should fail",
        student_id: student_other_school.id
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               StudentsInsights.create_student_insight(current_user, attrs)

      assert "student is invalid or from different school" in errors_on(changeset).student_id
    end

    test "create_student_insight/2 fails when student_ids is empty" do
      {current_user, _school, _staff_member, _profile} = create_user_with_profile()

      attrs = %{
        description: "This should fail",
        student_id: nil
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               StudentsInsights.create_student_insight(current_user, attrs)

      assert "student is required" in errors_on(changeset).student_id
    end

    test "create_student_insight/2 fails when no student_ids provided but student_ids key exists" do
      {current_user, _school, _staff_member, _profile} = create_user_with_profile()

      attrs = %{
        description: "This should fail",
        student_id: nil
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               StudentsInsights.create_student_insight(current_user, attrs)

      assert "student is required" in errors_on(changeset).student_id
    end

    test "create_student_insight/2 fails when no student is provided" do
      {current_user, _school, _staff_member, _profile} = create_user_with_profile()

      attrs = %{
        description: "This should fail without student"
      }

      # This should fail because student_id is required
      assert {:error, %Ecto.Changeset{} = changeset} =
               StudentsInsights.create_student_insight(current_user, attrs)

      assert "can't be blank" in errors_on(changeset).student_id
    end

    test "update_student_insight/3 can update student relationship" do
      {current_user, school, staff_member, _profile} = create_user_with_profile()

      student1 = insert(:student, school: school, name: "Student 1")
      student2 = insert(:student, school: school, name: "Student 2")

      insight =
        insert(:student_insight,
          school: school,
          author: staff_member,
          student: student1
        )

      update_attrs = %{
        description: "Updated description",
        student_id: student2.id
      }

      assert {:ok, %StudentInsight{} = updated_insight} =
               StudentsInsights.update_student_insight(current_user, insight, update_attrs)

      updated_insight_with_student = Lanttern.Repo.preload(updated_insight, :student)

      assert updated_insight.description == "Updated description"
      assert updated_insight_with_student.student.id == student2.id
    end

    test "update_student_insight/3 fails with cross-school student" do
      {current_user, school, staff_member, _profile} = create_user_with_profile()

      student_same_school =
        insert(:student,
          school: school,
          name: "Same School Update #{System.unique_integer([:positive])}"
        )

      other_school = insert(:school)

      student_other_school =
        insert(:student,
          school: other_school,
          name: "Other School Update #{System.unique_integer([:positive])}"
        )

      insight =
        insert(:student_insight,
          school: school,
          author: staff_member,
          student: student_same_school
        )

      update_attrs = %{
        student_id: student_other_school.id
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               StudentsInsights.update_student_insight(current_user, insight, update_attrs)

      assert "student is invalid or from different school" in errors_on(changeset).student_id
    end
  end
end
