defmodule Lanttern.StudentRecordReports do
  @moduledoc """
  The StudentRecordReports context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.StudentRecordReports.StudentRecordReport
  alias Lanttern.StudentRecordReports.StudentRecordReportAIConfig

  alias Lanttern.Schools
  alias Lanttern.StudentsRecords
  alias Lanttern.StudentsRecords.StudentRecord

  @doc """
  Returns the list of student_record_report_ai_config.

  ## Examples

      iex> list_student_record_report_ai_config()
      [%StudentRecordReportAIConfig{}, ...]

  """
  def list_student_record_report_ai_config do
    Repo.all(StudentRecordReportAIConfig)
  end

  @doc """
  Gets a single student_record_report_ai_config.

  Raises `Ecto.NoResultsError` if the Student record report ai config does not exist.

  ## Examples

      iex> get_student_record_report_ai_config!(123)
      %StudentRecordReportAIConfig{}

      iex> get_student_record_report_ai_config!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_record_report_ai_config!(id), do: Repo.get!(StudentRecordReportAIConfig, id)

  @doc """
  Gets a single student_record_report_ai_config by school_id.

  Returns `{:error, :no_config}` if the Student record report ai config does not exist.

  ## Examples

      iex> get_student_record_report_ai_config_by_school_id(123)
      %StudentRecordReportAIConfig{}

      iex> get_student_record_report_ai_config_by_school_id(456)
      {:error, :no_config}

  """
  @spec get_student_record_report_ai_config_by_school_id(school_id :: pos_integer()) ::
          StudentRecordReportAIConfig.t() | {:error, :no_config}
  def get_student_record_report_ai_config_by_school_id(school_id) do
    Repo.get_by(StudentRecordReportAIConfig, school_id: school_id)
    |> case do
      nil -> {:error, :no_config}
      config -> config
    end
  end

  @doc """
  Creates a student_record_report_ai_config.

  ## Examples

      iex> create_student_record_report_ai_config(%{field: value})
      {:ok, %StudentRecordReportAIConfig{}}

      iex> create_student_record_report_ai_config(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_record_report_ai_config(attrs \\ %{}) do
    %StudentRecordReportAIConfig{}
    |> StudentRecordReportAIConfig.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_record_report_ai_config.

  ## Examples

      iex> update_student_record_report_ai_config(student_record_report_ai_config, %{field: new_value})
      {:ok, %StudentRecordReportAIConfig{}}

      iex> update_student_record_report_ai_config(student_record_report_ai_config, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_record_report_ai_config(
        %StudentRecordReportAIConfig{} = student_record_report_ai_config,
        attrs
      ) do
    student_record_report_ai_config
    |> StudentRecordReportAIConfig.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_record_report_ai_config.

  ## Examples

      iex> delete_student_record_report_ai_config(student_record_report_ai_config)
      {:ok, %StudentRecordReportAIConfig{}}

      iex> delete_student_record_report_ai_config(student_record_report_ai_config)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_record_report_ai_config(
        %StudentRecordReportAIConfig{} = student_record_report_ai_config
      ) do
    Repo.delete(student_record_report_ai_config)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_record_report_ai_config changes.

  ## Examples

      iex> change_student_record_report_ai_config(student_record_report_ai_config)
      %Ecto.Changeset{data: %StudentRecordReportAIConfig{}}

  """
  def change_student_record_report_ai_config(
        %StudentRecordReportAIConfig{} = student_record_report_ai_config,
        attrs \\ %{}
      ) do
    StudentRecordReportAIConfig.changeset(student_record_report_ai_config, attrs)
  end

  @doc """
  Returns the list of student_record_reports.

  ## Options

  - `:student_id` - filter results by student

  ## Examples

      iex> list_student_record_reports()
      [%StudentRecordReport{}, ...]

  """
  def list_student_record_reports(opts \\ []) do
    from(
      srr in StudentRecordReport,
      order_by: [desc: srr.inserted_at]
    )
    |> apply_list_student_record_reports(opts)
    |> Repo.all()
  end

  defp apply_list_student_record_reports(queryable, []), do: queryable

  defp apply_list_student_record_reports(queryable, [{:student_id, id} | opts]) do
    from(
      srr in queryable,
      where: srr.student_id == ^id
    )
    |> apply_list_student_record_reports(opts)
  end

  defp apply_list_student_record_reports(queryable, [_ | opts]),
    do: apply_list_student_record_reports(queryable, opts)

  @doc """
  Gets a single student_record_report.

  Raises `Ecto.NoResultsError` if the Student record report does not exist.

  ## Examples

      iex> get_student_record_report!(123)
      %StudentRecordReport{}

      iex> get_student_record_report!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_record_report!(id), do: Repo.get!(StudentRecordReport, id)

  @doc """
  Creates a student_record_report.

  ## Examples

      iex> create_student_record_report(%{description: value, student_id: value})
      {:ok, %StudentRecordReport{}}

      iex> create_student_record_report(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_record_report(attrs \\ %{}) do
    %StudentRecordReport{}
    |> StudentRecordReport.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_record_report.

  ## Examples

      iex> update_student_record_report(student_record_report, %{description: new_value, student_id: value})
      {:ok, %StudentRecordReport{}}

      iex> update_student_record_report(student_record_report, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_record_report(%StudentRecordReport{} = student_record_report, attrs) do
    student_record_report
    |> StudentRecordReport.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_record_report.

  ## Examples

      iex> delete_student_record_report(student_record_report)
      {:ok, %StudentRecordReport{}}

      iex> delete_student_record_report(student_record_report)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_record_report(%StudentRecordReport{} = student_record_report) do
    Repo.delete(student_record_report)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_record_report changes.

  ## Examples

      iex> change_student_record_report(student_record_report)
      %Ecto.Changeset{data: %StudentRecordReport{}}

  """
  def change_student_record_report(%StudentRecordReport{} = student_record_report, attrs \\ %{}) do
    StudentRecordReport.changeset(student_record_report, attrs)
  end

  @doc """
  Generates a student record report for a given student.

  ## Options

  - `last_report`: The last report to use as a base for the new report

  ## Testing

  We use `open_ai_responses_module` as argument to allow mocking in tests.

  View https://blog.appsignal.com/2023/04/11/an-introduction-to-mocking-tools-for-elixir.html for reference.

  ## Examples

      iex> generate_student_record_report(123)
      {:ok, %StudentRecordReport{}}

      iex> generate_student_record_report(123, last_report: %StudentRecordReport{})
      {:ok, %StudentRecordReport{}}

      iex> generate_student_record_report(123, last_report: %StudentRecordReport{})
      {:error, :no_config}
  """
  @spec generate_student_record_report(
          student_id :: pos_integer(),
          opts :: Keyword.t(),
          open_ai_responses_module :: any()
        ) ::
          {:ok, StudentRecordReport.t()}
          | {:error, :no_config}
          | {:error, :no_records}
          | {:error, Ecto.Changeset.t()}
  def generate_student_record_report(
        student_id,
        opts \\ [],
        open_ai_responses_module \\ ExOpenAI.Responses
      ) do
    student = Schools.get_student!(student_id)

    with %StudentRecordReportAIConfig{} = config <-
           get_student_record_report_ai_config_by_school_id(student.school_id),
         %StudentRecordReportAIConfig{} = config <-
           validate_ai_config(config, Keyword.get(opts, :last_report)),
         student_records when is_list(student_records) <-
           list_and_validate_student_records(student.id, opts) do
      input =
        [
          %ExOpenAI.Components.EasyInputMessage{
            content: "Formatting re-enabled",
            role: :developer,
            type: :message
          },
          %ExOpenAI.Components.EasyInputMessage{
            content: config.summary_instructions,
            role: :developer,
            type: :message
          }
        ]

      input =
        case Keyword.get(opts, :last_report) do
          %StudentRecordReport{} = srr ->
            input ++
              [
                %ExOpenAI.Components.EasyInputMessage{
                  content: config.update_instructions,
                  role: :developer,
                  type: :message
                },
                %ExOpenAI.Components.EasyInputMessage{
                  content:
                    "# Last report\n\nBased on records up to: #{srr.to_datetime}\n\n#{srr.description}",
                  role: :user,
                  type: :message
                }
              ]

          _ ->
            input
        end

      input =
        input ++
          [
            %ExOpenAI.Components.EasyInputMessage{
              content: Enum.map_join(student_records, "\n\n---\n\n", &student_record_to_text/1),
              role: :user,
              type: :message
            }
          ]

      case open_ai_responses_module.create_response(input, config.model) do
        {:ok, %ExOpenAI.Components.Response{} = response} ->
          %{
            content: [
              %{
                text: report
              }
            ]
          } =
            response.output
            |> Enum.find(&(&1[:type] == "message" && &1[:role] == "assistant"))

          attrs =
            %{
              student_id: student_id,
              description: report
            }

          attrs =
            case Keyword.get(opts, :last_report) do
              %StudentRecordReport{} = srr ->
                Map.put(attrs, :from_datetime, srr.to_datetime)

              _ ->
                attrs
            end

          create_student_record_report(attrs)

        error ->
          error
      end
    end
  end

  defp validate_ai_config(%StudentRecordReportAIConfig{} = config, nil)
       when is_binary(config.summary_instructions) and is_binary(config.model),
       do: config

  defp validate_ai_config(%StudentRecordReportAIConfig{} = config, %StudentRecordReport{})
       when is_binary(config.summary_instructions) and is_binary(config.update_instructions) and
              is_binary(config.model),
       do: config

  defp validate_ai_config(_, _), do: {:error, :no_config}

  defp list_and_validate_student_records(student_id, opts) do
    list_opts =
      [
        students_ids: [student_id],
        preloads: [:students, :tags, :classes]
      ]

    list_opts =
      case Keyword.get(opts, :last_report) do
        %StudentRecordReport{} = srr ->
          [{:updated_after, srr.to_datetime} | list_opts]

        _ ->
          list_opts
      end

    StudentsRecords.list_students_records(list_opts)
    |> case do
      records when records == [] -> {:error, :no_records}
      records -> records
    end
  end

  defp student_record_to_text(%StudentRecord{} = record) do
    students =
      Enum.map_join(record.students, ", ", & &1.name)

    classes =
      if record.classes != [],
        do: Enum.map_join(record.tags, ", ", & &1.name),
        else: "-"

    tags =
      if record.tags != [],
        do: Enum.map_join(record.tags, ", ", & &1.name),
        else: "-"

    """
    # Student record id #{record.id}

    - Students: #{students}
    - Classes: #{classes}
    - Tags: #{tags}
    - Created at: #{record.inserted_at}
    - Record datetime: #{record.date} #{record.time || "(no time specified)"}

    #{if record.name, do: "## #{record.name}"}

    #{record.description}
    """
  end
end
