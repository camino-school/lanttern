defmodule Lanttern.TaxonomyTest do
  use Lanttern.DataCase

  alias Lanttern.Taxonomy

  describe "subjects" do
    alias Lanttern.Taxonomy.Subject

    import Lanttern.TaxonomyFixtures

    @invalid_attrs %{name: nil}

    test "list_subjects/0 returns all subjects" do
      subject = subject_fixture()
      assert Taxonomy.list_subjects() == [subject]
    end

    test "list_assessment_point_subjects/0 returns all subjects ordered alphabetically and separated in two lists: related and not related to assessment points" do
      subject_1 = subject_fixture(%{name: "AAA"})
      subject_2 = subject_fixture(%{name: "ZZZ"})

      curriculum_item_1 =
        Lanttern.CurriculaFixtures.curriculum_item_fixture(%{
          subjects_ids: [subject_1.id, subject_2.id]
        })

      curriculum_item_2 =
        Lanttern.CurriculaFixtures.curriculum_item_fixture(%{subjects_ids: [subject_2.id]})

      Lanttern.AssessmentsFixtures.assessment_point_fixture(%{
        curriculum_item_id: curriculum_item_1.id
      })

      Lanttern.AssessmentsFixtures.assessment_point_fixture(%{
        curriculum_item_id: curriculum_item_2.id
      })

      # extra fixtures for "filter" testing
      no_subject_1 = subject_fixture(%{name: "BBB"})
      no_subject_2 = subject_fixture(%{name: "YYY"})
      Lanttern.CurriculaFixtures.curriculum_item_fixture()
      Lanttern.CurriculaFixtures.curriculum_item_fixture()
      Lanttern.AssessmentsFixtures.assessment_point_fixture()
      Lanttern.AssessmentsFixtures.assessment_point_fixture()

      assert {[subject_1, subject_2], [no_subject_1, no_subject_2]} ==
               Taxonomy.list_assessment_points_subjects()
    end

    test "get_subject!/1 returns the subject with given id" do
      subject = subject_fixture()
      assert Taxonomy.get_subject!(subject.id) == subject
    end

    test "get_subject_by_code!/1 returns the subject with given code" do
      subject = subject_fixture(%{code: "sub123"})
      assert Taxonomy.get_subject_by_code!("sub123") == subject
    end

    test "create_subject/1 with valid data creates a subject" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Subject{} = subject} = Taxonomy.create_subject(valid_attrs)
      assert subject.name == "some name"
    end

    test "create_subject/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Taxonomy.create_subject(@invalid_attrs)
    end

    test "update_subject/2 with valid data updates the subject" do
      subject = subject_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Subject{} = subject} = Taxonomy.update_subject(subject, update_attrs)
      assert subject.name == "some updated name"
    end

    test "update_subject/2 with invalid data returns error changeset" do
      subject = subject_fixture()
      assert {:error, %Ecto.Changeset{}} = Taxonomy.update_subject(subject, @invalid_attrs)
      assert subject == Taxonomy.get_subject!(subject.id)
    end

    test "delete_subject/1 deletes the subject" do
      subject = subject_fixture()
      assert {:ok, %Subject{}} = Taxonomy.delete_subject(subject)
      assert_raise Ecto.NoResultsError, fn -> Taxonomy.get_subject!(subject.id) end
    end

    test "change_subject/1 returns a subject changeset" do
      subject = subject_fixture()
      assert %Ecto.Changeset{} = Taxonomy.change_subject(subject)
    end
  end

  describe "years" do
    alias Lanttern.Taxonomy.Year

    import Lanttern.TaxonomyFixtures

    @invalid_attrs %{name: nil}

    test "list_years/0 returns all years" do
      year = year_fixture()
      assert Taxonomy.list_years() == [year]
    end

    test "get_year!/1 returns the year with given id" do
      year = year_fixture()
      assert Taxonomy.get_year!(year.id) == year
    end

    test "get_year_by_code!/1 returns the year with given code" do
      year = year_fixture(%{code: "y123"})
      assert Taxonomy.get_year_by_code!("y123") == year
    end

    test "create_year/1 with valid data creates a year" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Year{} = year} = Taxonomy.create_year(valid_attrs)
      assert year.name == "some name"
    end

    test "create_year/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Taxonomy.create_year(@invalid_attrs)
    end

    test "update_year/2 with valid data updates the year" do
      year = year_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Year{} = year} = Taxonomy.update_year(year, update_attrs)
      assert year.name == "some updated name"
    end

    test "update_year/2 with invalid data returns error changeset" do
      year = year_fixture()
      assert {:error, %Ecto.Changeset{}} = Taxonomy.update_year(year, @invalid_attrs)
      assert year == Taxonomy.get_year!(year.id)
    end

    test "delete_year/1 deletes the year" do
      year = year_fixture()
      assert {:ok, %Year{}} = Taxonomy.delete_year(year)
      assert_raise Ecto.NoResultsError, fn -> Taxonomy.get_year!(year.id) end
    end

    test "change_year/1 returns a year changeset" do
      year = year_fixture()
      assert %Ecto.Changeset{} = Taxonomy.change_year(year)
    end
  end
end
