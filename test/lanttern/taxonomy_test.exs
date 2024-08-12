defmodule Lanttern.TaxonomyTest do
  use Lanttern.DataCase

  alias Lanttern.Taxonomy

  describe "subjects" do
    alias Lanttern.Taxonomy.Subject
    import Lanttern.TaxonomyFixtures

    alias Lanttern.LearningContextFixtures

    @invalid_attrs %{name: nil}

    test "list_subjects/1 returns all subjects" do
      subject = subject_fixture()
      assert Taxonomy.list_subjects() == [subject]
    end

    test "list_subjects/1 with ids filter returns subjects ordered alphabetically and filtered by id" do
      subject_a = subject_fixture(%{name: "AAA"})
      subject_b = subject_fixture(%{name: "BBB"})

      # extra subjects for filtering
      subject_fixture()
      subject_fixture()

      assert Taxonomy.list_subjects(ids: [subject_a.id, subject_b.id]) == [subject_a, subject_b]
    end

    test "list_strand_subjects/1 returns all subjects linked to the given strand" do
      subject_a = subject_fixture(%{name: "AAA"})
      subject_b = subject_fixture(%{name: "BBB"})

      strand =
        LearningContextFixtures.strand_fixture(%{subjects_ids: [subject_a.id, subject_b.id]})

      # extra subjects for filter test
      other_subject = subject_fixture()
      LearningContextFixtures.strand_fixture(%{subjects_ids: [other_subject.id]})

      assert Taxonomy.list_strand_subjects(strand.id) == [subject_a, subject_b]
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

    test "generate_subjects_code_id_map/0 returns a map with subject code as keys and its ids as value" do
      sub_1 = subject_fixture(%{code: "abc"})
      sub_2 = subject_fixture(%{code: "xyz"})

      expected = Taxonomy.generate_subjects_code_id_map()
      assert expected["abc"] == sub_1.id
      assert expected["xyz"] == sub_2.id
    end
  end

  describe "years" do
    alias Lanttern.Taxonomy.Year

    import Lanttern.TaxonomyFixtures

    @invalid_attrs %{name: nil}

    test "list_years/1 returns all years" do
      year = year_fixture()
      assert Taxonomy.list_years() == [year]
    end

    test "list_years/1 with ids filter returns years ordered and filtered by id" do
      year_1 = year_fixture()
      year_2 = year_fixture()

      # extra years for filtering
      year_fixture()
      year_fixture()

      assert Taxonomy.list_years(ids: [year_1.id, year_2.id]) == [year_1, year_2]
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

    test "generate_years_code_id_map/0 returns a map with year code as keys and its ids as value" do
      year_1 = year_fixture(%{code: "abc"})
      year_2 = year_fixture(%{code: "xyz"})

      expected = Taxonomy.generate_years_code_id_map()
      assert expected["abc"] == year_1.id
      assert expected["xyz"] == year_2.id
    end
  end
end
