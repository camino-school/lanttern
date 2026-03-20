defmodule Lanttern.GradingTest do
  use Lanttern.DataCase

  alias Lanttern.Grading

  describe "grade_components" do
    alias Lanttern.Grading.GradeComponent

    import Lanttern.GradingFixtures
    alias Lanttern.GradesReportsFixtures

    @invalid_attrs %{position: nil, weight: nil}

    test "list_grade_components/0 returns all grade_components" do
      grade_component = grade_component_fixture()
      assert Grading.list_grade_components() == [grade_component]
    end

    test "get_grade_component!/1 returns the grade_component with given id" do
      grade_component = grade_component_fixture()
      assert Grading.get_grade_component!(grade_component.id) == grade_component
    end

    test "create_grade_component/1 with valid data creates a grade_component" do
      assessment_point = Lanttern.AssessmentsFixtures.assessment_point_fixture()
      grades_report = GradesReportsFixtures.grades_report_fixture()

      grades_report_cycle =
        GradesReportsFixtures.grades_report_cycle_fixture(%{grades_report_id: grades_report.id})

      grades_report_subject =
        GradesReportsFixtures.grades_report_subject_fixture(%{grades_report_id: grades_report.id})

      valid_attrs = %{
        weight: 120.5,
        assessment_point_id: assessment_point.id,
        grades_report_id: grades_report.id,
        grades_report_cycle_id: grades_report_cycle.id,
        grades_report_subject_id: grades_report_subject.id
      }

      assert {:ok, %GradeComponent{} = grade_component} =
               Grading.create_grade_component(valid_attrs)

      assert grade_component.weight == 120.5
      assert grade_component.assessment_point_id == assessment_point.id
      assert grade_component.grades_report_id == grades_report.id
      assert grade_component.grades_report_cycle_id == grades_report_cycle.id
      assert grade_component.grades_report_subject_id == grades_report_subject.id
    end

    test "create_grade_component/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_grade_component(@invalid_attrs)
    end

    test "update_grade_component/2 with valid data updates the grade_component" do
      grade_component = grade_component_fixture()
      update_attrs = %{position: 43, weight: 456.7}

      assert {:ok, %GradeComponent{} = grade_component} =
               Grading.update_grade_component(grade_component, update_attrs)

      assert grade_component.position == 43
      assert grade_component.weight == 456.7
    end

    test "update_grade_component/2 with invalid data returns error changeset" do
      grade_component = grade_component_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Grading.update_grade_component(grade_component, @invalid_attrs)

      assert grade_component == Grading.get_grade_component!(grade_component.id)
    end

    test "update_grade_components_positions/1 update grade components positions based on list order" do
      grades_report = GradesReportsFixtures.grades_report_fixture()

      grades_report_cycle =
        GradesReportsFixtures.grades_report_cycle_fixture(%{grades_report_id: grades_report.id})

      grades_report_subject =
        GradesReportsFixtures.grades_report_subject_fixture(%{grades_report_id: grades_report.id})

      grade_component_1 =
        grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject.id
        })

      grade_component_2 =
        grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject.id
        })

      grade_component_3 =
        grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject.id
        })

      grade_component_4 =
        grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject.id
        })

      sorted_grade_components_ids =
        [
          grade_component_2.id,
          grade_component_3.id,
          grade_component_1.id,
          grade_component_4.id
        ]

      assert :ok == Grading.update_grade_components_positions(sorted_grade_components_ids)

      assert Grading.get_grade_component!(grade_component_2.id).position == 0
      assert Grading.get_grade_component!(grade_component_3.id).position == 1
      assert Grading.get_grade_component!(grade_component_1.id).position == 2
      assert Grading.get_grade_component!(grade_component_4.id).position == 3
    end

    test "delete_grade_component/1 deletes the grade_component" do
      grade_component = grade_component_fixture()
      assert {:ok, %GradeComponent{}} = Grading.delete_grade_component(grade_component)

      assert_raise Ecto.NoResultsError, fn ->
        Grading.get_grade_component!(grade_component.id)
      end
    end

    test "change_grade_component/1 returns a grade_component changeset" do
      grade_component = grade_component_fixture()
      assert %Ecto.Changeset{} = Grading.change_grade_component(grade_component)
    end
  end

  describe "scales" do
    alias Lanttern.Grading.Scale

    import Lanttern.Factory
    import Lanttern.IdentityFixtures

    @invalid_attrs %{name: nil, start: nil, stop: nil, type: nil}

    @invalid_numeric_attrs %{name: "0 to 10", start: nil, stop: nil, type: "numeric"}

    @invalid_breakpoint_attrs %{
      name: "Letter grades",
      start: nil,
      stop: nil,
      type: "ordinal",
      breakpoints: [0.5, 1.5]
    }

    setup do
      scope = scope_fixture(permissions: ["assessment_management"])
      %{scope: scope}
    end

    test "list_scales/1 returns all scales", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)
      assert Grading.list_scales(scope) == [scale]
    end

    test "list_scales/1 with preloads and scales_ids opts returns all scales as expected",
         %{scope: scope} do
      num_scale =
        insert(:scale, school_id: scope.school_id, type: "numeric", start: 0.0, stop: 100.0)

      ord_scale = insert(:scale, school_id: scope.school_id, type: "ordinal")
      ov_1 = insert(:ordinal_value, scale_id: ord_scale.id, normalized_value: 0.0)
      ov_2 = insert(:ordinal_value, scale_id: ord_scale.id, normalized_value: 1.0)

      # extra scale for filtering test
      insert(:scale, school_id: scope.school_id)

      assert scales =
               Grading.list_scales(ids: [num_scale.id, ord_scale.id], preloads: :ordinal_values)

      assert length(scales) == 2

      for scale <- scales do
        case scale do
          %{type: "ordinal"} ->
            assert scale.id == ord_scale.id
            assert [%{id: ov_1_id}, %{id: ov_2_id}] = scale.ordinal_values
            assert ov_1_id == ov_1.id
            assert ov_2_id == ov_2.id

          %{type: "numeric"} ->
            assert scale.id == num_scale.id
        end
      end
    end

    test "get_scale!/2 returns the scale with given id", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)
      assert Grading.get_scale!(scope, scale.id) == scale
    end

    test "get_scale!/2 with preloads returns the scale with given id and preloaded data",
         %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)
      ordinal_value = insert(:ordinal_value, scale_id: scale.id)

      result = Grading.get_scale!(scope, scale.id, preloads: :ordinal_values)
      ov_id = ordinal_value.id
      assert [%{id: ^ov_id}] = result.ordinal_values
    end

    test "create_scale/1 with valid data creates a scale", %{scope: scope} do
      valid_attrs = %{
        name: "some name",
        start: 120.5,
        stop: 120.5,
        type: "numeric",
        breakpoints: [0.4, 0.8]
      }

      assert {:ok, %Scale{} = scale} = Grading.create_scale(scope, valid_attrs)
      assert scale.name == "some name"
      assert scale.start == 120.5
      assert scale.stop == 120.5
      assert scale.type == "numeric"
      assert scale.breakpoints == [0.4, 0.8]
    end

    test "create_scale/1 orders and remove duplications of breakpoints", %{scope: scope} do
      valid_attrs = %{
        name: "some name",
        start: nil,
        stop: nil,
        type: "ordinal",
        breakpoints: [0.4, 0.8, 0.80, 0.6]
      }

      assert {:ok, %Scale{} = scale} = Grading.create_scale(scope, valid_attrs)
      assert scale.name == "some name"
      assert scale.type == "ordinal"
      assert scale.breakpoints == [0.4, 0.6, 0.8]
    end

    test "create_scale/1 with invalid data returns error changeset", %{scope: scope} do
      assert {:error, %Ecto.Changeset{}} = Grading.create_scale(scope, @invalid_attrs)
    end

    test "create_scale/1 of type numeric without start and stop returns error changeset",
         %{scope: scope} do
      assert {:error, %Ecto.Changeset{}} = Grading.create_scale(scope, @invalid_numeric_attrs)
    end

    test "create_scale/1 of with invalid breakpoints returns error changeset", %{scope: scope} do
      assert {:error, %Ecto.Changeset{}} = Grading.create_scale(scope, @invalid_breakpoint_attrs)
    end

    test "update_scale/2 with valid data updates the scale", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)

      update_attrs = %{
        name: "some updated name",
        start: 456.7,
        stop: 456.7,
        type: "numeric"
      }

      assert {:ok, %Scale{} = scale} = Grading.update_scale(scope, scale, update_attrs)
      assert scale.name == "some updated name"
      assert scale.start == 456.7
      assert scale.stop == 456.7
      assert scale.type == "numeric"
    end

    test "update_scale/2 with invalid data returns error changeset", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)
      assert {:error, %Ecto.Changeset{}} = Grading.update_scale(scope, scale, @invalid_attrs)
      assert scale == Grading.get_scale!(scope, scale.id)
    end

    test "delete_scale/1 deletes the scale", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)
      assert {:ok, %Scale{}} = Grading.delete_scale(scope, scale)
      assert_raise Ecto.NoResultsError, fn -> Grading.get_scale!(scope, scale.id) end
    end

    test "change_scale/1 returns a scale changeset", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)
      assert %Ecto.Changeset{} = Grading.change_scale(scope, scale)
    end
  end

  describe "ordinal_values" do
    alias Lanttern.Grading.OrdinalValue

    import Lanttern.Factory
    import Lanttern.IdentityFixtures

    @invalid_attrs %{name: nil, normalized_value: nil}

    setup do
      scope = scope_fixture(permissions: ["assessment_management"])
      %{scope: scope}
    end

    test "list_ordinal_values/1 returns all ordinal_values" do
      scale = insert(:scale)
      ordinal_value = insert(:ordinal_value, scale_id: scale.id)
      assert Grading.list_ordinal_values() == [ordinal_value]
    end

    test "list_ordinal_values/1 with preloads returns all ordinal_values with preloaded data" do
      scale = insert(:scale)
      ordinal_value = insert(:ordinal_value, scale_id: scale.id)

      [result] = Grading.list_ordinal_values(preloads: :scale)
      assert result.id == ordinal_value.id
      assert result.scale.id == scale.id
    end

    test "list_ordinal_values/1 with scale_id returns all ordinal_values from the specified scale ordered by normalized_value" do
      scale = insert(:scale)
      ordinal_value_1 = insert(:ordinal_value, scale_id: scale.id, normalized_value: 0.0)
      ordinal_value_2 = insert(:ordinal_value, scale_id: scale.id, normalized_value: 1.0)
      ordinal_value_3 = insert(:ordinal_value, scale_id: scale.id, normalized_value: 0.5)
      _other_ordinal_value = insert(:ordinal_value)

      assert Grading.list_ordinal_values(scale_id: scale.id) == [
               ordinal_value_1,
               ordinal_value_3,
               ordinal_value_2
             ]
    end

    test "list_ordinal_values/1 with ids returns all ordinal_values filtered by given ids" do
      ordinal_value_1 = insert(:ordinal_value, normalized_value: 0.0)
      ordinal_value_3 = insert(:ordinal_value, normalized_value: 1.0)
      ordinal_value_2 = insert(:ordinal_value, normalized_value: 0.5)
      _other_ordinal_value = insert(:ordinal_value)

      ids = [
        ordinal_value_1.id,
        ordinal_value_2.id,
        ordinal_value_3.id
      ]

      result_ids =
        Grading.list_ordinal_values(ids: ids)
        |> Enum.map(& &1.id)

      assert result_ids == [ordinal_value_1.id, ordinal_value_2.id, ordinal_value_3.id]
    end

    test "get_ordinal_value!/2 returns the ordinal_value with given id" do
      scale = insert(:scale)
      ordinal_value = insert(:ordinal_value, scale_id: scale.id)
      assert Grading.get_ordinal_value!(ordinal_value.id) == ordinal_value
    end

    test "get_ordinal_value!/2 with preloads returns the ordinal_value with given id and preloaded data" do
      scale = insert(:scale)
      ordinal_value = insert(:ordinal_value, scale_id: scale.id)

      result = Grading.get_ordinal_value!(ordinal_value.id, :scale)
      assert result.id == ordinal_value.id
      assert result.scale.id == scale.id
    end

    test "create_ordinal_value/1 with valid data creates a ordinal_value", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)

      valid_attrs = %{
        "name" => "some name",
        "normalized_value" => "0.5",
        "scale_id" => "#{scale.id}"
      }

      assert {:ok, %OrdinalValue{} = ordinal_value} =
               Grading.create_ordinal_value(scope, valid_attrs)

      assert ordinal_value.name == "some name"
      assert ordinal_value.normalized_value == 0.5
      assert ordinal_value.scale_id == scale.id
    end

    test "create_ordinal_value/1 with invalid data returns error changeset", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)

      assert {:error, %Ecto.Changeset{}} =
               Grading.create_ordinal_value(scope, %{
                 "scale_id" => "#{scale.id}",
                 "name" => nil,
                 "normalized_value" => nil
               })
    end

    test "create_ordinal_value/1 with invalid bg color returns error changeset", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)

      attrs = %{
        "scale_id" => "#{scale.id}",
        "name" => "some name",
        "normalized_value" => "1",
        "bg_color" => "000000"
      }

      assert {:error, %Ecto.Changeset{errors: [bg_color: _]}} =
               Grading.create_ordinal_value(scope, attrs)
    end

    test "create_ordinal_value/1 with invalid text color returns error changeset", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)

      attrs = %{
        "scale_id" => "#{scale.id}",
        "name" => "some name",
        "normalized_value" => "1",
        "text_color" => "ffffff"
      }

      assert {:error, %Ecto.Changeset{errors: [text_color: _]}} =
               Grading.create_ordinal_value(scope, attrs)
    end

    test "update_ordinal_value/2 with valid data updates the ordinal_value", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)
      ordinal_value = insert(:ordinal_value, scale_id: scale.id)
      update_attrs = %{name: "some updated name", normalized_value: 0.43}

      assert {:ok, %OrdinalValue{} = ordinal_value} =
               Grading.update_ordinal_value(scope, ordinal_value, update_attrs)

      assert ordinal_value.name == "some updated name"
      assert ordinal_value.normalized_value == 0.43
    end

    test "update_ordinal_value/2 with invalid data returns error changeset", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)
      ordinal_value = insert(:ordinal_value, scale_id: scale.id)

      assert {:error, %Ecto.Changeset{}} =
               Grading.update_ordinal_value(scope, ordinal_value, @invalid_attrs)

      assert ordinal_value.id == Grading.get_ordinal_value!(ordinal_value.id).id
    end

    test "delete_ordinal_value/1 deletes the ordinal_value", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)
      ordinal_value = insert(:ordinal_value, scale_id: scale.id)

      assert {:ok, %OrdinalValue{}} = Grading.delete_ordinal_value(scope, ordinal_value)
      assert_raise Ecto.NoResultsError, fn -> Grading.get_ordinal_value!(ordinal_value.id) end
    end

    test "change_ordinal_value/1 returns a ordinal_value changeset", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id)
      ordinal_value = insert(:ordinal_value, scale_id: scale.id)
      assert %Ecto.Changeset{} = Grading.change_ordinal_value(scope, ordinal_value)
    end
  end

  describe "conversions" do
    import Lanttern.Factory
    alias Lanttern.Grading.OrdinalValue

    test "convert_normalized_value_to_scale_value/1 returns the correct values for a ordinal scale" do
      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])

      ov_1 = insert(:ordinal_value, scale_id: scale.id, normalized_value: 0.3)
      ov_2 = insert(:ordinal_value, scale_id: scale.id, normalized_value: 0.6)
      ov_3 = insert(:ordinal_value, scale_id: scale.id, normalized_value: 1.0)

      ov_1_id = ov_1.id

      assert %OrdinalValue{id: ^ov_1_id} =
               Grading.convert_normalized_value_to_scale_value(0, scale)

      assert %OrdinalValue{id: ^ov_1_id} =
               Grading.convert_normalized_value_to_scale_value(0.39999, scale)

      ov_2_id = ov_2.id

      assert %OrdinalValue{id: ^ov_2_id} =
               Grading.convert_normalized_value_to_scale_value(0.4, scale)

      assert %OrdinalValue{id: ^ov_2_id} =
               Grading.convert_normalized_value_to_scale_value(0.6, scale)

      assert %OrdinalValue{id: ^ov_2_id} =
               Grading.convert_normalized_value_to_scale_value(0.79999, scale)

      ov_3_id = ov_3.id

      assert %OrdinalValue{id: ^ov_3_id} =
               Grading.convert_normalized_value_to_scale_value(0.8, scale)

      assert %OrdinalValue{id: ^ov_3_id} =
               Grading.convert_normalized_value_to_scale_value(0.962, scale)

      assert %OrdinalValue{id: ^ov_3_id} =
               Grading.convert_normalized_value_to_scale_value(1.0, scale)
    end

    test "convert_normalized_value_to_scale_value/1 returns the correct values for a numeric scale" do
      scale = insert(:scale, type: "numeric", start: 5.0, stop: 10.0)

      assert Grading.convert_normalized_value_to_scale_value(0, scale) == 5.0
      assert Grading.convert_normalized_value_to_scale_value(0.5, scale) == 7.5
      assert Grading.convert_normalized_value_to_scale_value(0.789, scale) == 8.945
      assert Grading.convert_normalized_value_to_scale_value(1, scale) == 10.0
    end
  end
end
