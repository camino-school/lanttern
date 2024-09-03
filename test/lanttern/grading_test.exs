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

    import Lanttern.GradingFixtures

    @invalid_attrs %{name: nil, start: nil, stop: nil, type: nil}

    @invalid_numeric_attrs %{name: "0 to 10", start: nil, stop: nil, type: "numeric"}

    @invalid_breakpoint_attrs %{
      name: "Letter grades",
      start: nil,
      stop: nil,
      type: "ordinal",
      breakpoints: [0.5, 1.5]
    }

    test "list_scales/1 returns all scales" do
      scale = scale_fixture()
      assert Grading.list_scales() == [scale]
    end

    test "list_scales/1 with preloads and scales_ids opts returns all scales as expected" do
      num_scale = scale_fixture(%{type: "numeric"})
      ord_scale = scale_fixture(%{type: "ordinal"})
      ov_1 = ordinal_value_fixture(%{scale_id: ord_scale.id, normalized_value: 0})
      ov_2 = ordinal_value_fixture(%{scale_id: ord_scale.id, normalized_value: 1})

      # extra scales for filtering test
      scale_fixture()

      assert scales =
               Grading.list_scales(ids: [num_scale.id, ord_scale.id], preloads: :ordinal_values)

      assert length(scales) == 2

      for scale <- scales do
        case scale do
          %{type: "ordinal"} ->
            assert scale.id == ord_scale.id
            assert scale.ordinal_values == [ov_1, ov_2]

          %{type: "numeric"} ->
            assert scale.id == num_scale.id
        end
      end
    end

    test "get_scale!/2 returns the scale with given id" do
      scale = scale_fixture()
      assert Grading.get_scale!(scale.id) == scale
    end

    test "get_scale!/2 with preloads returns the scale with given id and preloaded data" do
      scale = scale_fixture()

      ordinal_value =
        ordinal_value_fixture(%{scale_id: scale.id})
        |> Map.put(:scale, scale)

      expected_scale = Grading.get_scale!(scale.id, preloads: :ordinal_values)
      [expected_ordinal_value] = expected_scale.ordinal_values
      assert expected_ordinal_value.id == ordinal_value.id
    end

    test "create_scale/1 with valid data creates a scale" do
      valid_attrs = %{
        name: "some name",
        start: 120.5,
        stop: 120.5,
        type: "numeric",
        breakpoints: [0.4, 0.8]
      }

      assert {:ok, %Scale{} = scale} = Grading.create_scale(valid_attrs)
      assert scale.name == "some name"
      assert scale.start == 120.5
      assert scale.stop == 120.5
      assert scale.type == "numeric"
      assert scale.breakpoints == [0.4, 0.8]
    end

    test "create_scale/1 orders and remove duplications of breakpoints" do
      valid_attrs = %{
        name: "some name",
        start: nil,
        stop: nil,
        type: "ordinal",
        breakpoints: [0.4, 0.8, 0.80, 0.6]
      }

      assert {:ok, %Scale{} = scale} = Grading.create_scale(valid_attrs)
      assert scale.name == "some name"
      assert scale.type == "ordinal"
      assert scale.breakpoints == [0.4, 0.6, 0.8]
    end

    test "create_scale/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_scale(@invalid_attrs)
    end

    test "create_scale/1 of type numeric without start and stop returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_scale(@invalid_numeric_attrs)
    end

    test "create_scale/1 of with invalid breakpoints returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_scale(@invalid_breakpoint_attrs)
    end

    test "update_scale/2 with valid data updates the scale" do
      scale = scale_fixture()

      update_attrs = %{
        name: "some updated name",
        start: 456.7,
        stop: 456.7,
        type: "numeric"
      }

      assert {:ok, %Scale{} = scale} = Grading.update_scale(scale, update_attrs)
      assert scale.name == "some updated name"
      assert scale.start == 456.7
      assert scale.stop == 456.7
      assert scale.type == "numeric"
    end

    test "update_scale/2 with invalid data returns error changeset" do
      scale = scale_fixture()
      assert {:error, %Ecto.Changeset{}} = Grading.update_scale(scale, @invalid_attrs)
      assert scale == Grading.get_scale!(scale.id)
    end

    test "delete_scale/1 deletes the scale" do
      scale = scale_fixture()
      assert {:ok, %Scale{}} = Grading.delete_scale(scale)
      assert_raise Ecto.NoResultsError, fn -> Grading.get_scale!(scale.id) end
    end

    test "change_scale/1 returns a scale changeset" do
      scale = scale_fixture()
      assert %Ecto.Changeset{} = Grading.change_scale(scale)
    end
  end

  describe "ordinal_values" do
    alias Lanttern.Grading.OrdinalValue

    import Lanttern.GradingFixtures

    @invalid_attrs %{name: nil, normalized_value: nil}

    test "list_ordinal_values/1 returns all ordinal_values" do
      ordinal_value = ordinal_value_fixture()
      assert Grading.list_ordinal_values() == [ordinal_value]
    end

    test "list_ordinal_values/1 with preloads returns all ordinal_values with preloaded data" do
      scale = scale_fixture()

      ordinal_value =
        ordinal_value_fixture(%{scale_id: scale.id})
        |> Map.put(:scale, scale)

      assert Grading.list_ordinal_values(preloads: :scale) == [ordinal_value]
    end

    test "list_ordinal_values/1 with scale_id returns all ordinal_values from the specified scale ordered by normalized_value" do
      scale = scale_fixture()
      ordinal_value_1 = ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0})
      ordinal_value_2 = ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 1})
      ordinal_value_3 = ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.5})
      _other_ordinal_value = ordinal_value_fixture()

      assert Grading.list_ordinal_values(scale_id: scale.id) == [
               ordinal_value_1,
               ordinal_value_3,
               ordinal_value_2
             ]
    end

    test "list_ordinal_values/1 with ids returns all ordinal_values filtered by given ids" do
      ordinal_value_1 = ordinal_value_fixture(%{normalized_value: 0})
      ordinal_value_3 = ordinal_value_fixture(%{normalized_value: 1})
      ordinal_value_2 = ordinal_value_fixture(%{normalized_value: 0.5})
      _other_ordinal_value = ordinal_value_fixture()

      ids = [
        ordinal_value_1.id,
        ordinal_value_2.id,
        ordinal_value_3.id
      ]

      assert Grading.list_ordinal_values(ids: ids) == [
               ordinal_value_1,
               ordinal_value_2,
               ordinal_value_3
             ]
    end

    test "get_ordinal_value!/2 returns the ordinal_value with given id" do
      ordinal_value = ordinal_value_fixture()
      assert Grading.get_ordinal_value!(ordinal_value.id) == ordinal_value
    end

    test "get_ordinal_value!/2 with preloads returns the ordinal_value with given id and preloaded data" do
      scale = scale_fixture()

      ordinal_value =
        ordinal_value_fixture(%{scale_id: scale.id})
        |> Map.put(:scale, scale)

      assert Grading.get_ordinal_value!(ordinal_value.id, :scale) == ordinal_value
    end

    test "create_ordinal_value/1 with valid data creates a ordinal_value" do
      scale = scale_fixture()
      valid_attrs = %{name: "some name", normalized_value: 0.5, scale_id: scale.id}

      assert {:ok, %OrdinalValue{} = ordinal_value} = Grading.create_ordinal_value(valid_attrs)
      assert ordinal_value.name == "some name"
      assert ordinal_value.normalized_value == 0.5
      assert ordinal_value.scale_id == scale.id
    end

    test "create_ordinal_value/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Grading.create_ordinal_value(@invalid_attrs)
    end

    test "create_ordinal_value/1 with invalid bg color returns error changeset" do
      scale = scale_fixture(%{type: "ordinal"})

      attrs = %{
        scale_id: scale.id,
        name: "some name",
        normalized_value: 1,
        bg_color: "000000"
      }

      assert {:error, %Ecto.Changeset{errors: [bg_color: _]}} =
               Grading.create_ordinal_value(attrs)
    end

    test "create_ordinal_value/1 with invalid text color returns error changeset" do
      scale = scale_fixture(%{type: "ordinal"})

      attrs = %{
        scale_id: scale.id,
        name: "some name",
        normalized_value: 1,
        text_color: "ffffff"
      }

      assert {:error, %Ecto.Changeset{errors: [text_color: _]}} =
               Grading.create_ordinal_value(attrs)
    end

    test "update_ordinal_value/2 with valid data updates the ordinal_value" do
      ordinal_value = ordinal_value_fixture()
      update_attrs = %{name: "some updated name", normalized_value: 0.43}

      assert {:ok, %OrdinalValue{} = ordinal_value} =
               Grading.update_ordinal_value(ordinal_value, update_attrs)

      assert ordinal_value.name == "some updated name"
      assert ordinal_value.normalized_value == 0.43
    end

    test "update_ordinal_value/2 with invalid data returns error changeset" do
      ordinal_value = ordinal_value_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Grading.update_ordinal_value(ordinal_value, @invalid_attrs)

      assert ordinal_value == Grading.get_ordinal_value!(ordinal_value.id)
    end

    test "delete_ordinal_value/1 deletes the ordinal_value" do
      ordinal_value = ordinal_value_fixture()
      assert {:ok, %OrdinalValue{}} = Grading.delete_ordinal_value(ordinal_value)
      assert_raise Ecto.NoResultsError, fn -> Grading.get_ordinal_value!(ordinal_value.id) end
    end

    test "change_ordinal_value/1 returns a ordinal_value changeset" do
      ordinal_value = ordinal_value_fixture()
      assert %Ecto.Changeset{} = Grading.change_ordinal_value(ordinal_value)
    end
  end

  describe "conversions" do
    import Lanttern.GradingFixtures
    alias Lanttern.Grading.OrdinalValue

    test "convert_normalized_value_to_scale_value/1 returns the correct values for a ordinal scale" do
      scale =
        scale_fixture(%{
          type: "ordinal",
          breakpoints: [0.4, 0.8]
        })

      ov_1 =
        ordinal_value_fixture(%{
          scale_id: scale.id,
          normalized_value: 0.3
        })

      ov_2 =
        ordinal_value_fixture(%{
          scale_id: scale.id,
          normalized_value: 0.6
        })

      ov_3 =
        ordinal_value_fixture(%{
          scale_id: scale.id,
          normalized_value: 1.0
        })

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
      scale =
        scale_fixture(%{
          type: "numeric",
          start: 5.0,
          stop: 10.0
        })

      assert Grading.convert_normalized_value_to_scale_value(0, scale) == 5.0
      assert Grading.convert_normalized_value_to_scale_value(0.5, scale) == 7.5
      assert Grading.convert_normalized_value_to_scale_value(0.789, scale) == 8.945
      assert Grading.convert_normalized_value_to_scale_value(1, scale) == 10.0
    end
  end
end
