defmodule Lanttern.ILPTest do
  use Lanttern.DataCase

  alias Lanttern.ILP

  describe "ilp_templates" do
    alias Lanttern.ILP.ILPTemplate

    import Lanttern.ILPFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_ilp_templates/0 returns all ilp_templates" do
      ilp_template = ilp_template_fixture()
      assert ILP.list_ilp_templates() == [ilp_template]
    end

    test "get_ilp_template!/1 returns the ilp_template with given id" do
      ilp_template = ilp_template_fixture()
      assert ILP.get_ilp_template!(ilp_template.id) == ilp_template
    end

    test "create_ilp_template/1 with valid data creates a ilp_template" do
      school = Lanttern.SchoolsFixtures.school_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        school_id: school.id
      }

      assert {:ok, %ILPTemplate{} = ilp_template} = ILP.create_ilp_template(valid_attrs)
      assert ilp_template.name == "some name"
      assert ilp_template.description == "some description"
      assert ilp_template.school_id == school.id
    end

    test "create_ilp_template/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ILP.create_ilp_template(@invalid_attrs)
    end

    test "update_ilp_template/2 with valid data updates the ilp_template" do
      ilp_template = ilp_template_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description"
      }

      assert {:ok, %ILPTemplate{} = ilp_template} =
               ILP.update_ilp_template(ilp_template, update_attrs)

      assert ilp_template.name == "some updated name"
      assert ilp_template.description == "some updated description"
    end

    test "update_ilp_template/2 with invalid data returns error changeset" do
      ilp_template = ilp_template_fixture()
      assert {:error, %Ecto.Changeset{}} = ILP.update_ilp_template(ilp_template, @invalid_attrs)
      assert ilp_template == ILP.get_ilp_template!(ilp_template.id)
    end

    test "delete_ilp_template/1 deletes the ilp_template" do
      ilp_template = ilp_template_fixture()
      assert {:ok, %ILPTemplate{}} = ILP.delete_ilp_template(ilp_template)
      assert_raise Ecto.NoResultsError, fn -> ILP.get_ilp_template!(ilp_template.id) end
    end

    test "change_ilp_template/1 returns a ilp_template changeset" do
      ilp_template = ilp_template_fixture()
      assert %Ecto.Changeset{} = ILP.change_ilp_template(ilp_template)
    end
  end

  describe "ilp_sections" do
    alias Lanttern.ILP.ILPSection

    import Lanttern.ILPFixtures

    @invalid_attrs %{name: nil, position: nil}

    test "list_ilp_sections/0 returns all ilp_sections" do
      ilp_section = ilp_section_fixture()
      assert ILP.list_ilp_sections() == [ilp_section]
    end

    test "get_ilp_section!/1 returns the ilp_section with given id" do
      ilp_section = ilp_section_fixture()
      assert ILP.get_ilp_section!(ilp_section.id) == ilp_section
    end

    test "create_ilp_section/1 with valid data creates a ilp_section" do
      template = ilp_template_fixture()
      valid_attrs = %{name: "some name", position: 42, template_id: template.id}

      assert {:ok, %ILPSection{} = ilp_section} = ILP.create_ilp_section(valid_attrs)
      assert ilp_section.name == "some name"
      assert ilp_section.position == 42
      assert ilp_section.template_id == template.id
    end

    test "create_ilp_section/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ILP.create_ilp_section(@invalid_attrs)
    end

    test "update_ilp_section/2 with valid data updates the ilp_section" do
      ilp_section = ilp_section_fixture()
      update_attrs = %{name: "some updated name", position: 43}

      assert {:ok, %ILPSection{} = ilp_section} =
               ILP.update_ilp_section(ilp_section, update_attrs)

      assert ilp_section.name == "some updated name"
      assert ilp_section.position == 43
    end

    test "update_ilp_section/2 with invalid data returns error changeset" do
      ilp_section = ilp_section_fixture()
      assert {:error, %Ecto.Changeset{}} = ILP.update_ilp_section(ilp_section, @invalid_attrs)
      assert ilp_section == ILP.get_ilp_section!(ilp_section.id)
    end

    test "delete_ilp_section/1 deletes the ilp_section" do
      ilp_section = ilp_section_fixture()
      assert {:ok, %ILPSection{}} = ILP.delete_ilp_section(ilp_section)
      assert_raise Ecto.NoResultsError, fn -> ILP.get_ilp_section!(ilp_section.id) end
    end

    test "change_ilp_section/1 returns a ilp_section changeset" do
      ilp_section = ilp_section_fixture()
      assert %Ecto.Changeset{} = ILP.change_ilp_section(ilp_section)
    end
  end
end
