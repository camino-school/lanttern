defmodule Lanttern.ILPTest do
  use Lanttern.DataCase

  alias Lanttern.ILP

  import Lanttern.Factory

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
        school_id: school.id,
        ai_layer: %{
          revision_instructions: "some revision instructions"
        }
      }

      assert {:ok, %ILPTemplate{} = ilp_template} = ILP.create_ilp_template(valid_attrs)
      assert ilp_template.name == "some name"
      assert ilp_template.description == "some description"
      assert ilp_template.school_id == school.id
      assert ilp_template.ai_layer.revision_instructions == "some revision instructions"
    end

    test "create_ilp_template/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ILP.create_ilp_template(@invalid_attrs)
    end

    test "update_ilp_template/2 with valid data updates the ilp_template" do
      ilp_template =
        ilp_template_fixture(%{
          ai_layer: %{
            revision_instructions: "some revision instructions"
          }
        })

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        ai_layer: %{
          template_id: ilp_template.id,
          revision_instructions: "some updated revision instructions"
        }
      }

      assert {:ok, %ILPTemplate{} = ilp_template} =
               ILP.update_ilp_template(ilp_template, update_attrs)

      assert ilp_template.name == "some updated name"
      assert ilp_template.description == "some updated description"
      assert ilp_template.ai_layer.revision_instructions == "some updated revision instructions"
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
      ilp_template =
        ilp_template_fixture(%{
          ai_layer: %{
            revision_instructions: "some revision instructions"
          }
        })

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

    alias Lanttern.ILP.StudentILP
    alias Lanttern.ILPLog.StudentILPLog
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

    test "student_has_ilp_for_cycle?/3 returns true if student has ILP for cycle" do
      school = SchoolsFixtures.school_fixture()
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})
      template = ilp_template_fixture(%{school_id: school.id})
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})

      student_ilp =
        student_ilp_fixture(%{
          student_id: student.id,
          school_id: school.id,
          cycle_id: cycle.id,
          template_id: template.id
        })

      # not shared yet
      refute ILP.student_has_ilp_for_cycle?(student.id, cycle.id, :shared_with_student)
      refute ILP.student_has_ilp_for_cycle?(student.id, cycle.id, :shared_with_guardians)

      # share and assert

      ILP.update_student_ilp_sharing(student_ilp, %{
        is_shared_with_student: true
      })

      assert ILP.student_has_ilp_for_cycle?(student.id, cycle.id, :shared_with_student)
      refute ILP.student_has_ilp_for_cycle?(student.id, cycle.id, :shared_with_guardians)
    end

    test "revise_student_ilp/5 returns the revised student ILP" do
      template =
        ilp_template_fixture(%{ai_layer: %{revision_instructions: "some revision instructions"}})
        |> Repo.preload(sections: :components)

      student_ilp =
        student_ilp_fixture(%{school_id: template.school_id, template_id: template.id})
        |> Repo.preload(:entries)

      # profile to test log
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

      {:ok, %StudentILP{} = student_ilp} =
        ILP.revise_student_ilp(
          student_ilp,
          template,
          10,
          [log_profile_id: profile.id],
          Lanttern.ExOpenAIStub.Responses
        )

      assert student_ilp.ai_revision == "This is a stub response."

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        student_ilp_log =
          Repo.get_by!(StudentILPLog,
            student_ilp_id: student_ilp.id
          )

        assert student_ilp_log.student_ilp_id == student_ilp.id
        assert student_ilp_log.profile_id == profile.id
        assert student_ilp_log.operation == "UPDATE"

        assert student_ilp_log.ai_revision == student_ilp.ai_revision
      end)
    end
  end

  describe "ilp_comments" do
    alias Lanttern.ILP.ILPComment

    setup do
      school = insert(:school)
      template = insert(:ilp_template, %{school: school})
      student = insert(:student, %{school: school})
      cycle = insert(:cycle, %{school: school})

      student_ilp =
        insert(:student_ilp, %{student: student, cycle: cycle, template: template, school: school})

      staff_member = insert(:staff_member, %{school: school})
      profile = insert(:profile, %{type: "staff", staff_member: staff_member})

      {:ok, student_ilp: student_ilp, profile: profile}
    end

    @invalid_attrs %{name: nil, position: nil, content: nil, shared_with_students: nil}

    test "list_ilp_comments/0 returns all ilp_comments" do
      ilp_comment = insert(:ilp_comment)

      assert ILP.list_ilp_comments() == [ilp_comment]
    end

    test "get_ilp_comment!/1 returns the ilp_comment with given id" do
      ilp_comment = insert(:ilp_comment)
      assert ILP.get_ilp_comment!(ilp_comment.id) == ilp_comment
    end

    test "create_ilp_comment/1 with valid data creates a ilp_comment", ctx do
      attrs = %{owner_id: ctx.profile.id, student_ilp_id: ctx.student_ilp.id}
      valid_attrs = params_for(:ilp_comment, attrs)

      assert {:ok, %ILPComment{} = ilp_comment} = ILP.create_ilp_comment(valid_attrs)

      assert ilp_comment.name == valid_attrs.name
      assert ilp_comment.position == valid_attrs.position
      assert ilp_comment.content == valid_attrs.content
      assert ilp_comment.shared_with_students == valid_attrs.shared_with_students
      assert ilp_comment.owner_id == ctx.profile.id
      assert ilp_comment.student_ilp_id == ctx.student_ilp.id
    end

    test "create_ilp_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ILP.create_ilp_comment(@invalid_attrs)
    end

    test "update_ilp_comment/2 with valid data updates the ilp_comment", ctx do
      ilp_comment = insert(:ilp_comment, %{owner: ctx.profile, student_ilp: ctx.student_ilp})
      update_attrs = %{name: "some", position: 43, content: "some", shared_with_students: false}

      assert {:ok, %ILPComment{} = ilp_comment} =
               ILP.update_ilp_comment(ilp_comment, update_attrs)

      assert ilp_comment.name == update_attrs.name
      assert ilp_comment.position == update_attrs.position
      assert ilp_comment.content == update_attrs.content
      assert ilp_comment.shared_with_students == update_attrs.shared_with_students
      assert ilp_comment.owner_id == ctx.profile.id
      assert ilp_comment.student_ilp_id == ctx.student_ilp.id
    end

    test "update_ilp_comment/2 with invalid data returns error changeset" do
      ilp_comment = insert(:ilp_comment)
      assert {:error, %Ecto.Changeset{}} = ILP.update_ilp_comment(ilp_comment, @invalid_attrs)
      assert ilp_comment == ILP.get_ilp_comment!(ilp_comment.id)
    end

    test "delete_ilp_comment/1 deletes the ilp_comment" do
      ilp_comment = insert(:ilp_comment)
      assert {:ok, %ILPComment{}} = ILP.delete_ilp_comment(ilp_comment)
      assert_raise Ecto.NoResultsError, fn -> ILP.get_ilp_comment!(ilp_comment.id) end
    end

    test "change_ilp_comment/1 returns a ilp_comment changeset" do
      ilp_comment = insert(:ilp_comment)
      assert %Ecto.Changeset{} = ILP.change_ilp_comment(ilp_comment)
    end
  end

  describe "ilp_comment_attachments" do
    alias Lanttern.ILP.ILPCommentAttachment

    import Lanttern.Factory

    @invalid_attrs %{position: nil, link: nil, shared_with_students: nil, is_external: nil}

    test "list_ilp_comment_attachments/0 returns all ilp_comment_attachments" do
      ilp_comment_attachment = insert(:ilp_comment_attachment)

      assert [subject] = ILP.list_ilp_comment_attachments()

      assert subject.id == ilp_comment_attachment.id
      assert subject.position == ilp_comment_attachment.position
      assert subject.link == ilp_comment_attachment.link
      assert subject.shared_with_students == ilp_comment_attachment.shared_with_students
      assert subject.is_external == ilp_comment_attachment.is_external
      assert subject.ilp_comment_id == ilp_comment_attachment.ilp_comment_id
    end

    test "get_ilp_comment_attachment!/1 returns the ilp_comment_attachment with given id" do
      ilp_comment_attachment = insert(:ilp_comment_attachment)

      assert subject = ILP.get_ilp_comment_attachment!(ilp_comment_attachment.id)

      assert subject.id == ilp_comment_attachment.id
      assert subject.position == ilp_comment_attachment.position
      assert subject.link == ilp_comment_attachment.link
      assert subject.shared_with_students == ilp_comment_attachment.shared_with_students
      assert subject.is_external == ilp_comment_attachment.is_external
      assert subject.ilp_comment_id == ilp_comment_attachment.ilp_comment_id
    end

    test "create_ilp_comment_attachment/1 with valid data creates a ilp_comment_attachment" do
      ilp_comment = insert(:ilp_comment)

      valid_attrs = %{
        name: "some name",
        ilp_comment_id: ilp_comment.id,
        position: 42,
        link: "some link",
        shared_with_students: true,
        is_external: true
      }

      assert {:ok, %ILPCommentAttachment{} = ilp_comment_attachment} =
               ILP.create_ilp_comment_attachment(valid_attrs)

      assert ilp_comment_attachment.position == 42
      assert ilp_comment_attachment.link == "some link"
      assert ilp_comment_attachment.shared_with_students == true
      assert ilp_comment_attachment.is_external == true
    end

    test "create_ilp_comment_attachment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ILP.create_ilp_comment_attachment(@invalid_attrs)
    end

    test "update_ilp_comment_attachment/2 with valid data updates the ilp_comment_attachment" do
      ilp_comment_attachment = insert(:ilp_comment_attachment)

      update_attrs = %{
        name: "some updated name",
        position: 43,
        link: "https://updated.link",
        shared_with_students: false,
        is_external: true
      }

      assert {:ok, %ILPCommentAttachment{} = ilp_comment_attachment} =
               ILP.update_ilp_comment_attachment(ilp_comment_attachment, update_attrs)

      assert ilp_comment_attachment.name == update_attrs.name
      assert ilp_comment_attachment.position == update_attrs.position
      assert ilp_comment_attachment.link == update_attrs.link
      assert ilp_comment_attachment.shared_with_students == false
      assert ilp_comment_attachment.is_external == true
    end

    test "update_ilp_comment_attachment/2 with invalid data returns error changeset" do
      ilp_comment_attachment = insert(:ilp_comment_attachment)

      assert {:error, %Ecto.Changeset{}} =
               ILP.update_ilp_comment_attachment(ilp_comment_attachment, @invalid_attrs)
    end

    test "delete_ilp_comment_attachment/1 deletes the ilp_comment_attachment" do
      ilp_comment_attachment = insert(:ilp_comment_attachment)

      assert {:ok, %ILPCommentAttachment{}} =
               ILP.delete_ilp_comment_attachment(ilp_comment_attachment)

      assert_raise Ecto.NoResultsError, fn ->
        ILP.get_ilp_comment_attachment!(ilp_comment_attachment.id)
      end
    end

    test "change_ilp_comment_attachment/1 returns a ilp_comment_attachment changeset" do
      ilp_comment_attachment = insert(:ilp_comment_attachment)
      assert %Ecto.Changeset{} = ILP.change_ilp_comment_attachment(ilp_comment_attachment)
    end
  end
end
