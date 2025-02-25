defmodule Lanttern.ILPTest do
  use Lanttern.DataCase

  alias Lanttern.ILP

  describe "ilp_templates" do
    alias Lanttern.ILP.ILPTemplate

    import Lanttern.ILPFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_ilp_templates/1 returns all ilp_templates" do
      ilp_template = ilp_template_fixture()
      assert ILP.list_ilp_templates() == [ilp_template]
    end

    test "list_ilp_templates/1 with school_id opt returns all school ilp_templates" do
      school = Lanttern.SchoolsFixtures.school_fixture()
      ilp_template = ilp_template_fixture(%{school_id: school.id})

      # extra fixture to test filter
      ilp_template_fixture()

      assert ILP.list_ilp_templates(school_id: school.id) == [ilp_template]
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

    test "update_ilp_template/2 with valid nested data inserts sections and components to the template" do
      ilp_template = ilp_template_fixture() |> Repo.preload(sections: :components)

      valid_attrs = %{
        sections: [
          %{
            name: "section 1",
            position: 0,
            components: [
              %{name: "component 1 1", position: 0, template_id: ilp_template.id},
              %{name: "component 1 2", position: 1, template_id: ilp_template.id}
            ]
          },
          %{
            name: "section 2",
            position: 1,
            components: [
              %{name: "component 2 1", position: 0, template_id: ilp_template.id},
              %{name: "component 2 2", position: 1, template_id: ilp_template.id}
            ]
          }
        ]
      }

      assert {:ok, %ILPTemplate{} = expected} =
               ILP.update_ilp_template(ilp_template, valid_attrs)

      expected = Repo.preload(expected, sections: :components)

      assert expected.name == ilp_template.name
      assert expected.description == ilp_template.description
      assert expected.school_id == ilp_template.school_id

      [section_1, section_2] = expected.sections
      assert section_1.name == "section 1"
      assert section_2.name == "section 2"

      [component_1_1, component_1_2] = section_1.components
      assert component_1_1.name == "component 1 1"
      assert component_1_2.name == "component 1 2"

      [component_2_1, component_2_2] = section_2.components
      assert component_2_1.name == "component 2 1"
      assert component_2_2.name == "component 2 2"
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
      ilp_section_1 = ilp_section_fixture(%{position: 1})
      ilp_section_2 = ilp_section_fixture(%{position: 2})
      ilp_section_3 = ilp_section_fixture(%{position: 3})

      assert ILP.list_ilp_sections() == [ilp_section_1, ilp_section_2, ilp_section_3]

      # use same setup to test update_ilp_sections_positions/1

      ILP.update_ilp_sections_positions([
        ilp_section_2.id,
        ilp_section_3.id,
        ilp_section_1.id
      ])

      [expected_section_2, expected_section_3, expected_section_1] = ILP.list_ilp_sections()
      assert expected_section_1.id == ilp_section_1.id
      assert expected_section_2.id == ilp_section_2.id
      assert expected_section_3.id == ilp_section_3.id
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

  describe "ilp_components" do
    alias Lanttern.ILP.ILPComponent

    import Lanttern.ILPFixtures

    @invalid_attrs %{name: nil, position: nil}

    test "list_ilp_components/0 returns all ilp_components" do
      ilp_component_1 = ilp_component_fixture(%{position: 1})
      ilp_component_2 = ilp_component_fixture(%{position: 2})
      ilp_component_3 = ilp_component_fixture(%{position: 3})

      assert ILP.list_ilp_components() == [ilp_component_1, ilp_component_2, ilp_component_3]

      # use same setup to test update_ilp_components_positions/1

      ILP.update_ilp_components_positions([
        ilp_component_2.id,
        ilp_component_3.id,
        ilp_component_1.id
      ])

      [expected_component_2, expected_component_3, expected_component_1] =
        ILP.list_ilp_components()

      assert expected_component_1.id == ilp_component_1.id
      assert expected_component_2.id == ilp_component_2.id
      assert expected_component_3.id == ilp_component_3.id
    end

    test "get_ilp_component!/1 returns the ilp_component with given id" do
      ilp_component = ilp_component_fixture()
      assert ILP.get_ilp_component!(ilp_component.id) == ilp_component
    end

    test "create_ilp_component/1 with valid data creates a ilp_component" do
      template = ilp_template_fixture()
      section = ilp_section_fixture(%{template_id: template.id})

      valid_attrs = %{
        name: "some name",
        position: 42,
        template_id: template.id,
        section_id: section.id
      }

      assert {:ok, %ILPComponent{} = ilp_component} = ILP.create_ilp_component(valid_attrs)
      assert ilp_component.name == "some name"
      assert ilp_component.position == 42
      assert ilp_component.template_id == template.id
      assert ilp_component.section_id == section.id
    end

    test "create_ilp_component/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ILP.create_ilp_component(@invalid_attrs)
    end

    test "update_ilp_component/2 with valid data updates the ilp_component" do
      ilp_component = ilp_component_fixture()
      update_attrs = %{name: "some updated name", position: 43}

      assert {:ok, %ILPComponent{} = ilp_component} =
               ILP.update_ilp_component(ilp_component, update_attrs)

      assert ilp_component.name == "some updated name"
      assert ilp_component.position == 43
    end

    test "update_ilp_component/2 with invalid data returns error changeset" do
      ilp_component = ilp_component_fixture()
      assert {:error, %Ecto.Changeset{}} = ILP.update_ilp_component(ilp_component, @invalid_attrs)
      assert ilp_component == ILP.get_ilp_component!(ilp_component.id)
    end

    test "delete_ilp_component/1 deletes the ilp_component" do
      ilp_component = ilp_component_fixture()
      assert {:ok, %ILPComponent{}} = ILP.delete_ilp_component(ilp_component)
      assert_raise Ecto.NoResultsError, fn -> ILP.get_ilp_component!(ilp_component.id) end
    end

    test "change_ilp_component/1 returns a ilp_component changeset" do
      ilp_component = ilp_component_fixture()
      assert %Ecto.Changeset{} = ILP.change_ilp_component(ilp_component)
    end
  end

  describe "students_ilps" do
    alias Lanttern.ILP.StudentILP

    import Lanttern.ILPFixtures

    @invalid_attrs %{school_id: nil}

    test "list_students_ilps/0 returns all students_ilps" do
      student_ilp = student_ilp_fixture()
      assert ILP.list_students_ilps() == [student_ilp]
    end

    test "get_student_ilp!/1 returns the student_ilp with given id" do
      student_ilp = student_ilp_fixture()
      assert ILP.get_student_ilp!(student_ilp.id) == student_ilp
    end

    test "get_student_ilp_by/1 returns the student_ilp matching given clauses" do
      student_ilp = student_ilp_fixture()

      # create updated student ilp to test include_updates opt
      student_ilp_fixture(%{
        school_id: student_ilp.school_id,
        student_id: student_ilp.student_id,
        template_id: student_ilp.template_id,
        cycle_id: student_ilp.cycle_id,
        update_of_ilp_id: student_ilp.id
      })

      assert ILP.get_student_ilp_by(
               student_id: student_ilp.student_id,
               template_id: student_ilp.template_id,
               cycle_id: student_ilp.cycle_id
             ) == student_ilp
    end

    test "create_student_ilp/1 with valid data creates a student_ilp" do
      school = Lanttern.SchoolsFixtures.school_fixture()
      cycle = Lanttern.SchoolsFixtures.cycle_fixture(%{school_id: school.id})
      student = Lanttern.SchoolsFixtures.student_fixture(%{school_id: school.id})
      template = ilp_template_fixture(%{school_id: school.id})

      valid_attrs =
        %{
          school_id: school.id,
          cycle_id: cycle.id,
          student_id: student.id,
          template_id: template.id,
          teacher_notes: "some teacher notes"
        }

      assert {:ok, %StudentILP{} = student_ilp} = ILP.create_student_ilp(valid_attrs)
      assert student_ilp.school_id == school.id
      assert student_ilp.cycle_id == cycle.id
      assert student_ilp.student_id == student.id
      assert student_ilp.template_id == template.id
      assert student_ilp.teacher_notes == "some teacher notes"
    end

    test "create_student_ilp/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ILP.create_student_ilp(@invalid_attrs)
    end

    test "update_student_ilp/2 with valid data updates the student_ilp" do
      student_ilp = student_ilp_fixture()
      update_attrs = %{teacher_notes: "some updated teacher notes"}

      assert {:ok, %StudentILP{} = student_ilp} =
               ILP.update_student_ilp(student_ilp, update_attrs)

      assert student_ilp.teacher_notes == "some updated teacher notes"
    end

    test "update_student_ilp/2 with invalid data returns error changeset" do
      student_ilp = student_ilp_fixture()
      assert {:error, %Ecto.Changeset{}} = ILP.update_student_ilp(student_ilp, @invalid_attrs)
      assert student_ilp == ILP.get_student_ilp!(student_ilp.id)
    end

    test "delete_student_ilp/1 deletes the student_ilp" do
      student_ilp = student_ilp_fixture()
      assert {:ok, %StudentILP{}} = ILP.delete_student_ilp(student_ilp)
      assert_raise Ecto.NoResultsError, fn -> ILP.get_student_ilp!(student_ilp.id) end
    end

    test "change_student_ilp/1 returns a student_ilp changeset" do
      student_ilp = student_ilp_fixture()
      assert %Ecto.Changeset{} = ILP.change_student_ilp(student_ilp)
    end
  end
end
