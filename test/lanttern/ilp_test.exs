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
    alias Lanttern.ILPLog.StudentILPLog

    import Lanttern.ILPFixtures
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{school_id: nil}

    test "list_students_ilps/0 returns all students_ilps" do
      student_ilp = student_ilp_fixture()
      assert ILP.list_students_ilps() == [student_ilp]
    end

    test "list_students_ilps/1 returns all students_ilps filtered by given options" do
      cycle = SchoolsFixtures.cycle_fixture()
      school_id = cycle.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id})
      template_1 = ilp_template_fixture(%{school_id: school_id})
      template_2 = ilp_template_fixture(%{school_id: school_id})
      template_3 = ilp_template_fixture(%{school_id: school_id})

      student_ilp_1 =
        student_ilp_fixture(%{
          school_id: school_id,
          student_id: student.id,
          cycle_id: cycle.id,
          template_id: template_1.id
        })

      ILP.update_student_ilp_sharing(student_ilp_1, %{
        is_shared_with_student: true
      })

      student_ilp_2 =
        student_ilp_fixture(%{
          school_id: school_id,
          student_id: student.id,
          cycle_id: cycle.id,
          template_id: template_2.id
        })

      ILP.update_student_ilp_sharing(student_ilp_2, %{
        is_shared_with_student: true
      })

      # extra fixture to test filter

      _another_cycle_ilp =
        student_ilp_fixture(%{
          school_id: school_id,
          student_id: student.id,
          template_id: template_1.id
        })

      _another_student_ilp =
        student_ilp_fixture(%{
          school_id: school_id,
          cycle_id: cycle.id,
          template_id: template_2.id
        })

      not_shared_with_student =
        student_ilp_fixture(%{
          school_id: school_id,
          student_id: student.id,
          cycle_id: cycle.id,
          template_id: template_3.id
        })

      ILP.update_student_ilp_sharing(not_shared_with_student, %{
        is_shared_with_guardians: true
      })

      expected =
        ILP.list_students_ilps(
          student_id: student.id,
          cycle_id: cycle.id,
          only_shared_with_student: true
        )

      assert length(expected) == 2
      assert Enum.any?(expected, fn ilp -> ilp.id == student_ilp_1.id end)
      assert Enum.any?(expected, fn ilp -> ilp.id == student_ilp_2.id end)
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

      template =
        ilp_template_fixture(%{school_id: school.id}) |> Repo.preload(sections: :components)

      # add sections and components to the template

      {:ok, %{sections: [%{components: [component]}]} = template} =
        ILP.update_ilp_template(template, %{
          sections: [
            %{
              name: "section 1",
              position: 0,
              components: [
                %{name: "component 1", template_id: template.id}
              ]
            }
          ]
        })

      component_id = component.id

      # profile to test log
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

      valid_attrs =
        %{
          school_id: school.id,
          cycle_id: cycle.id,
          student_id: student.id,
          template_id: template.id,
          teacher_notes: "some teacher notes",
          entries: [
            %{
              template_id: template.id,
              component_id: component_id,
              description: "some entry description"
            }
          ]
        }

      assert {:ok, %StudentILP{} = student_ilp} =
               ILP.create_student_ilp(valid_attrs, log_profile_id: profile.id)

      assert student_ilp.school_id == school.id
      assert student_ilp.cycle_id == cycle.id
      assert student_ilp.student_id == student.id
      assert student_ilp.template_id == template.id
      assert student_ilp.teacher_notes == "some teacher notes"

      [entry] = student_ilp.entries
      assert entry.component_id == component_id
      assert entry.description == "some entry description"

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        student_ilp_log =
          Repo.get_by!(StudentILPLog,
            student_ilp_id: student_ilp.id
          )

        assert student_ilp_log.student_ilp_id == student_ilp.id
        assert student_ilp_log.profile_id == profile.id
        assert student_ilp_log.operation == "CREATE"

        assert student_ilp_log.school_id == student_ilp.school_id
        assert student_ilp_log.cycle_id == student_ilp.cycle_id
        assert student_ilp_log.student_id == student_ilp.student_id
        assert student_ilp_log.template_id == student_ilp.template_id
        assert student_ilp_log.teacher_notes == student_ilp.teacher_notes

        [entry_log] = student_ilp_log.entries
        assert entry_log.id == entry.id
        assert entry_log.component_id == entry.component_id
        assert entry_log.description == entry.description
      end)
    end

    test "create_student_ilp/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ILP.create_student_ilp(@invalid_attrs)
    end

    test "update_student_ilp/2 with valid data updates the student_ilp" do
      template =
        ilp_template_fixture()
        |> Repo.preload(sections: :components)

      # add sections and components to the template

      {:ok, %{sections: [%{components: [component]}]} = template} =
        ILP.update_ilp_template(template, %{
          sections: [
            %{
              name: "section 1",
              position: 0,
              components: [
                %{name: "component 1", template_id: template.id}
              ]
            }
          ]
        })

      component_id = component.id

      student_ilp =
        student_ilp_fixture(%{school_id: template.school_id, template_id: template.id})
        |> Repo.preload(:entries)

      update_attrs = %{
        teacher_notes: "some updated teacher notes",
        entries: [
          %{
            template_id: template.id,
            component_id: component_id,
            description: "some updated entry description"
          }
        ]
      }

      # profile to test log
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

      assert {:ok, %StudentILP{} = student_ilp} =
               ILP.update_student_ilp(student_ilp, update_attrs, log_profile_id: profile.id)

      assert student_ilp.teacher_notes == "some updated teacher notes"

      [entry] = student_ilp.entries
      assert entry.description == "some updated entry description"

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        student_ilp_log =
          Repo.get_by!(StudentILPLog,
            student_ilp_id: student_ilp.id
          )

        assert student_ilp_log.student_ilp_id == student_ilp.id
        assert student_ilp_log.profile_id == profile.id
        assert student_ilp_log.operation == "UPDATE"

        assert student_ilp_log.school_id == student_ilp.school_id
        assert student_ilp_log.cycle_id == student_ilp.cycle_id
        assert student_ilp_log.student_id == student_ilp.student_id
        assert student_ilp_log.template_id == student_ilp.template_id
        assert student_ilp_log.teacher_notes == student_ilp.teacher_notes

        [entry_log] = student_ilp_log.entries
        assert entry_log.id == entry.id
        assert entry_log.component_id == entry.component_id
        assert entry_log.description == entry.description
      end)
    end

    test "update_student_ilp_sharing/2 with valid data updates the student_ilp" do
      student_ilp = student_ilp_fixture()

      update_attrs = %{
        is_shared_with_student: true,
        is_shared_with_guardians: true
      }

      # profile to test log
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

      assert {:ok, %StudentILP{} = student_ilp} =
               ILP.update_student_ilp_sharing(student_ilp, update_attrs,
                 log_profile_id: profile.id
               )

      assert student_ilp.is_shared_with_student
      assert student_ilp.is_shared_with_guardians

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        student_ilp_log =
          Repo.get_by!(StudentILPLog,
            student_ilp_id: student_ilp.id
          )

        assert student_ilp_log.student_ilp_id == student_ilp.id
        assert student_ilp_log.profile_id == profile.id
        assert student_ilp_log.operation == "UPDATE"

        assert student_ilp_log.is_shared_with_student
        assert student_ilp_log.is_shared_with_guardians
      end)
    end

    test "update_student_ilp/2 with invalid data returns error changeset" do
      student_ilp = student_ilp_fixture()
      assert {:error, %Ecto.Changeset{}} = ILP.update_student_ilp(student_ilp, @invalid_attrs)
      assert student_ilp == ILP.get_student_ilp!(student_ilp.id)
    end

    test "delete_student_ilp/1 deletes the student_ilp" do
      student_ilp = student_ilp_fixture()

      # profile to test log
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

      assert {:ok, %StudentILP{}} =
               ILP.delete_student_ilp(student_ilp, log_profile_id: profile.id)

      assert_raise Ecto.NoResultsError, fn -> ILP.get_student_ilp!(student_ilp.id) end

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        student_ilp_log =
          Repo.get_by!(StudentILPLog,
            student_ilp_id: student_ilp.id
          )

        assert student_ilp_log.student_ilp_id == student_ilp.id
        assert student_ilp_log.profile_id == profile.id
        assert student_ilp_log.operation == "DELETE"
      end)
    end

    test "change_student_ilp/1 returns a student_ilp changeset" do
      student_ilp = student_ilp_fixture()
      assert %Ecto.Changeset{} = ILP.change_student_ilp(student_ilp)
    end
  end

  describe "extra" do
    import Lanttern.ILPFixtures

    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    test "list_students_and_ilps/4 returns students and ILPs" do
      # Set up school, cycle, and template
      school = SchoolsFixtures.school_fixture()
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})
      template = ilp_template_fixture(%{school_id: school.id})

      # Create class
      class =
        SchoolsFixtures.class_fixture(%{
          school_id: school.id,
          cycle_id: cycle.id
        })

      # Create students and assign to classes
      student_a =
        SchoolsFixtures.student_fixture(%{
          name: "AAA",
          school_id: school.id,
          classes_ids: [class.id]
        })

      student_b =
        SchoolsFixtures.student_fixture(%{
          name: "BBB",
          school_id: school.id,
          classes_ids: [class.id]
        })

      student_c =
        SchoolsFixtures.student_fixture(%{
          name: "CCC",
          school_id: school.id
        })

      # Create student ILPs for some students
      ilp_a =
        student_ilp_fixture(%{
          student_id: student_a.id,
          school_id: school.id,
          cycle_id: cycle.id,
          template_id: template.id
        })

      # extra fixtures to test filter

      _deactivated_student =
        SchoolsFixtures.student_fixture(%{
          school_id: school.id,
          deactivated_at: DateTime.utc_now(),
          classes_ids: [class.id]
        })

      _other_school = SchoolsFixtures.student_fixture()

      _other_cycle_ilp_b =
        student_ilp_fixture(%{
          student_id: student_b.id,
          school_id: school.id,
          template_id: template.id
        })

      _other_template_ilp_c =
        student_ilp_fixture(%{
          student_id: student_c.id,
          school_id: school.id,
          cycle_id: cycle.id
        })

      # Get the result
      [
        {expected_student_a, expected_ilp_a},
        {expected_student_b, nil},
        {expected_student_c, nil}
      ] = ILP.list_students_and_ilps(school.id, cycle.id, template.id)

      # Assertions
      assert expected_student_a.id == student_a.id
      assert expected_ilp_a.id == ilp_a.id
      assert expected_student_b.id == student_b.id
      assert expected_student_c.id == student_c.id

      # use same setup to test class filter
      [
        {expected_student_a, expected_ilp_a},
        {expected_student_b, nil}
      ] =
        ILP.list_students_and_ilps(school.id, cycle.id, template.id, classes_ids: [class.id])

      assert expected_student_a.id == student_a.id
      assert expected_ilp_a.id == ilp_a.id
      assert expected_student_b.id == student_b.id
    end

    test "list_ilp_classes_metrics/3 returns correct numbers" do
      # Set up school, cycle, and template
      school = SchoolsFixtures.school_fixture()
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})
      template = ilp_template_fixture(%{school_id: school.id})

      # Create class
      year_1 = TaxonomyFixtures.year_fixture()
      year_2 = TaxonomyFixtures.year_fixture()

      class_1 =
        SchoolsFixtures.class_fixture(%{
          school_id: school.id,
          cycle_id: cycle.id,
          years_ids: [year_1.id]
        })

      class_2 =
        SchoolsFixtures.class_fixture(%{
          school_id: school.id,
          cycle_id: cycle.id,
          years_ids: [year_2.id]
        })

      # Create students and assign to classes
      student_1_1 =
        SchoolsFixtures.student_fixture(%{
          school_id: school.id,
          classes_ids: [class_1.id]
        })

      student_1_2 =
        SchoolsFixtures.student_fixture(%{
          school_id: school.id,
          classes_ids: [class_1.id]
        })

      student_1_3 =
        SchoolsFixtures.student_fixture(%{
          school_id: school.id,
          classes_ids: [class_1.id]
        })

      student_2_1 =
        SchoolsFixtures.student_fixture(%{
          school_id: school.id,
          classes_ids: [class_2.id]
        })

      student_2_2 =
        SchoolsFixtures.student_fixture(%{
          school_id: school.id,
          classes_ids: [class_2.id]
        })

      deactivated_student_2_3 =
        SchoolsFixtures.student_fixture(%{
          school_id: school.id,
          classes_ids: [class_2.id],
          deactivated_at: DateTime.utc_now()
        })

      # Create student ILPs for some students
      _student_1_1_ilp =
        student_ilp_fixture(%{
          student_id: student_1_1.id,
          school_id: school.id,
          cycle_id: cycle.id,
          template_id: template.id
        })

      _student_1_2_ilp =
        student_ilp_fixture(%{
          student_id: student_1_2.id,
          school_id: school.id,
          cycle_id: cycle.id,
          template_id: template.id
        })

      _student_1_3_ilp =
        student_ilp_fixture(%{
          student_id: student_1_3.id,
          school_id: school.id,
          cycle_id: cycle.id,
          template_id: template.id
        })

      # extra fixtures to test filter

      _student_2_1_another_template =
        student_ilp_fixture(%{
          student_id: student_2_1.id,
          school_id: school.id,
          cycle_id: cycle.id
        })

      _student_2_2_another_cycle =
        student_ilp_fixture(%{
          student_id: student_2_2.id,
          school_id: school.id,
          template_id: template.id
        })

      _student_2_3_deactivated =
        student_ilp_fixture(%{
          student_id: deactivated_student_2_3.id,
          school_id: school.id,
          cycle_id: cycle.id,
          template_id: template.id
        })

      # Get the result
      [
        {expected_class_1, 3, 3},
        {expected_class_2, 2, 0}
      ] = ILP.list_ilp_classes_metrics(school.id, cycle.id, template.id)

      # Assertions
      assert expected_class_1.id == class_1.id
      assert expected_class_2.id == class_2.id
    end
  end
end
