defmodule Lanttern.ILP do
  @moduledoc """
  The ILP context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers

  alias Lanttern.ILP.ILPTemplate
  alias Lanttern.ILP.ILPTemplateAILayer
  alias Lanttern.ILPLog
  alias Lanttern.Repo
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.Student

  @doc """
  Returns the list of ilp_templates.

  ## Options

  - `:school_id` - filter results by school id
  - `:preloads` – preloads associated data

  ## Examples

      iex> list_ilp_templates()
      [%ILPTemplate{}, ...]

  """
  def list_ilp_templates(opts \\ []) do
    from(
      t in ILPTemplate,
      order_by: t.name
    )
    |> apply_list_ilp_templates_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_ilp_templates_opts(queryable, []), do: queryable

  defp apply_list_ilp_templates_opts(queryable, [{:school_id, school_id} | opts]) do
    from(
      t in queryable,
      where: t.school_id == ^school_id
    )
    |> apply_list_ilp_templates_opts(opts)
  end

  defp apply_list_ilp_templates_opts(queryable, [_ | opts]),
    do: apply_list_ilp_templates_opts(queryable, opts)

  @doc """
  Gets a single ilp_template.

  Raises `Ecto.NoResultsError` if the Ilp template does not exist.

  ## Options

  - `:preloads` – preloads associated data

  ## Examples

      iex> get_ilp_template!(123)
      %ILPTemplate{}

      iex> get_ilp_template!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ilp_template!(id, opts \\ []) do
    ILPTemplate
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a ilp_template.

  ## Examples

      iex> create_ilp_template(%{field: value})
      {:ok, %ILPTemplate{}}

      iex> create_ilp_template(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ilp_template(attrs \\ %{}) do
    %ILPTemplate{}
    |> ILPTemplate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ilp_template.

  ## Examples

      iex> update_ilp_template(ilp_template, %{field: new_value})
      {:ok, %ILPTemplate{}}

      iex> update_ilp_template(ilp_template, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ilp_template(%ILPTemplate{} = ilp_template, attrs) do
    ilp_template
    |> ILPTemplate.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ilp_template.

  ## Examples

      iex> delete_ilp_template(ilp_template)
      {:ok, %ILPTemplate{}}

      iex> delete_ilp_template(ilp_template)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ilp_template(%ILPTemplate{} = ilp_template) do
    Repo.delete(ilp_template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ilp_template changes.

  ## Examples

      iex> change_ilp_template(ilp_template)
      %Ecto.Changeset{data: %ILPTemplate{}}

  """
  def change_ilp_template(%ILPTemplate{} = ilp_template, attrs \\ %{}) do
    ILPTemplate.changeset(ilp_template, attrs)
  end

  alias Lanttern.ILP.ILPSection

  @doc """
  Returns the list of ilp_sections.

  ## Examples

      iex> list_ilp_sections()
      [%ILPSection{}, ...]

  """
  def list_ilp_sections do
    from(
      s in ILPSection,
      order_by: s.position
    )
    |> Repo.all()
  end

  @doc """
  Gets a single ilp_section.

  Raises `Ecto.NoResultsError` if the Ilp section does not exist.

  ## Examples

      iex> get_ilp_section!(123)
      %ILPSection{}

      iex> get_ilp_section!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ilp_section!(id), do: Repo.get!(ILPSection, id)

  @doc """
  Creates a ilp_section.

  ## Examples

      iex> create_ilp_section(%{field: value})
      {:ok, %ILPSection{}}

      iex> create_ilp_section(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ilp_section(attrs \\ %{}) do
    %ILPSection{}
    |> ILPSection.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ilp_section.

  ## Examples

      iex> update_ilp_section(ilp_section, %{field: new_value})
      {:ok, %ILPSection{}}

      iex> update_ilp_section(ilp_section, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ilp_section(%ILPSection{} = ilp_section, attrs) do
    ilp_section
    |> ILPSection.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Update ILP template sections positions based on ids list order.

  ## Examples

  iex> update_ilp_sections_positions([3, 2, 1])
  :ok

  """
  @spec update_ilp_sections_positions(sections_ids :: [pos_integer()]) ::
          :ok | {:error, String.t()}
  def update_ilp_sections_positions(sections_ids), do: update_positions(ILPSection, sections_ids)

  @doc """
  Deletes a ilp_section.

  ## Examples

      iex> delete_ilp_section(ilp_section)
      {:ok, %ILPSection{}}

      iex> delete_ilp_section(ilp_section)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ilp_section(%ILPSection{} = ilp_section) do
    Repo.delete(ilp_section)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ilp_section changes.

  ## Examples

      iex> change_ilp_section(ilp_section)
      %Ecto.Changeset{data: %ILPSection{}}

  """
  def change_ilp_section(%ILPSection{} = ilp_section, attrs \\ %{}) do
    ILPSection.changeset(ilp_section, attrs)
  end

  alias Lanttern.ILP.ILPComponent

  @doc """
  Returns the list of ilp_components.

  ## Examples

      iex> list_ilp_components()
      [%ILPComponent{}, ...]

  """
  def list_ilp_components do
    from(
      c in ILPComponent,
      order_by: c.position
    )
    |> Repo.all()
  end

  @doc """
  Gets a single ilp_component.

  Raises `Ecto.NoResultsError` if the Ilp component does not exist.

  ## Examples

      iex> get_ilp_component!(123)
      %ILPComponent{}

      iex> get_ilp_component!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ilp_component!(id), do: Repo.get!(ILPComponent, id)

  @doc """
  Creates a ilp_component.

  ## Examples

      iex> create_ilp_component(%{field: value})
      {:ok, %ILPComponent{}}

      iex> create_ilp_component(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ilp_component(attrs \\ %{}) do
    %ILPComponent{}
    |> ILPComponent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ilp_component.

  ## Examples

      iex> update_ilp_component(ilp_component, %{field: new_value})
      {:ok, %ILPComponent{}}

      iex> update_ilp_component(ilp_component, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ilp_component(%ILPComponent{} = ilp_component, attrs) do
    ilp_component
    |> ILPComponent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Update ILP section components positions based on ids list order.

  ## Examples

  iex> update_ilp_components_positions([3, 2, 1])
  :ok

  """
  @spec update_ilp_components_positions(sections_ids :: [pos_integer()]) ::
          :ok | {:error, String.t()}
  def update_ilp_components_positions(sections_ids),
    do: update_positions(ILPComponent, sections_ids)

  @doc """
  Deletes a ilp_component.

  ## Examples

      iex> delete_ilp_component(ilp_component)
      {:ok, %ILPComponent{}}

      iex> delete_ilp_component(ilp_component)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ilp_component(%ILPComponent{} = ilp_component) do
    Repo.delete(ilp_component)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ilp_component changes.

  ## Examples

      iex> change_ilp_component(ilp_component)
      %Ecto.Changeset{data: %ILPComponent{}}

  """
  def change_ilp_component(%ILPComponent{} = ilp_component, attrs \\ %{}) do
    ILPComponent.changeset(ilp_component, attrs)
  end

  alias Lanttern.ILP.StudentILP

  @doc """
  Returns the list of students_ilps.

  ## Options

  - `:student_id` - filter results by student
  - `:cycle_id` - filter results by cycle
  - `:only_shared_with_student` - boolean. Filter results by ILPs shared with student
  - `:only_shared_with_guardians` - boolean. Filter results by ILPs shared with guardians
  - `:preloads` – preloads associated data

  ## Examples

      iex> list_students_ilps()
      [%StudentILP{}, ...]

  """
  def list_students_ilps(opts \\ []) do
    StudentILP
    |> apply_list_students_ilps_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_students_ilps_opts(queryable, []), do: queryable

  defp apply_list_students_ilps_opts(queryable, [{:student_id, student_id} | opts]) do
    from(
      ilp in queryable,
      where: ilp.student_id == ^student_id
    )
    |> apply_list_students_ilps_opts(opts)
  end

  defp apply_list_students_ilps_opts(queryable, [{:cycle_id, cycle_id} | opts]) do
    from(
      ilp in queryable,
      where: ilp.cycle_id == ^cycle_id
    )
    |> apply_list_students_ilps_opts(opts)
  end

  defp apply_list_students_ilps_opts(queryable, [{:only_shared_with_student, true} | opts]) do
    from(
      ilp in queryable,
      where: ilp.is_shared_with_student
    )
    |> apply_list_students_ilps_opts(opts)
  end

  defp apply_list_students_ilps_opts(queryable, [{:only_shared_with_guardians, true} | opts]) do
    from(
      ilp in queryable,
      where: ilp.is_shared_with_guardians
    )
    |> apply_list_students_ilps_opts(opts)
  end

  defp apply_list_students_ilps_opts(queryable, [_ | opts]),
    do: apply_list_students_ilps_opts(queryable, opts)

  @doc """
  Gets a single student_ilp.

  Raises `Ecto.NoResultsError` if the Student ilp does not exist.

  ## Examples

      iex> get_student_ilp!(123)
      %StudentILP{}

      iex> get_student_ilp!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_ilp!(id), do: Repo.get!(StudentILP, id)

  @doc """
  Gets a single student_ilp by given clauses.

  `Repo.get_by/2` wrapper. Returns `nil` if no result was found.

  If there's no `update_of_ilp_id` in clauses, will filter only base ILPs.

  ## Options

  - `:preloads` – preloads associated data

  ## Examples

      iex> get_student_ilp_by(student_id: 1, cycle_id: 1, template_id: 1)
      %StudentILP{}

      iex> get_student_ilp_by(student_id: 1, cycle_id: 1, template_id: 999)
      nil

  """
  @spec get_student_ilp_by(clauses :: Keyword.t(), opts :: Keyword.t()) :: StudentILP.t() | nil
  def get_student_ilp_by(clauses, opts \\ []) do
    where =
      if Keyword.get(clauses, :update_of_ilp_id) do
        true
      else
        dynamic([ilp], is_nil(ilp.update_of_ilp_id))
      end

    from(
      ilp in StudentILP,
      where: ^where
    )
    |> Repo.get_by(clauses)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a student_ilp.

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> create_student_ilp(%{field: value})
      {:ok, %StudentILP{}}

      iex> create_student_ilp(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_ilp(attrs \\ %{}, opts \\ []) do
    %StudentILP{}
    |> StudentILP.changeset(attrs)
    |> Repo.insert()
    |> ILPLog.maybe_create_student_ilp_log("CREATE", opts)
  end

  @doc """
  Updates a student_ilp.

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> update_student_ilp(student_ilp, %{field: new_value})
      {:ok, %StudentILP{}}

      iex> update_student_ilp(student_ilp, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_ilp(%StudentILP{} = student_ilp, attrs, opts \\ []) do
    student_ilp
    |> StudentILP.changeset(attrs)
    |> Repo.update()
    |> ILPLog.maybe_create_student_ilp_log("UPDATE", opts)
  end

  @doc """
  Updates a student_ilp sharing fields.

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> update_student_ilp_sharing(student_ilp, %{field: new_value})
      {:ok, %StudentILP{}}

      iex> update_student_ilp_sharing(student_ilp, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_ilp_sharing(%StudentILP{} = student_ilp, attrs, opts \\ []) do
    student_ilp
    |> StudentILP.share_changeset(attrs)
    |> Repo.update()
    |> ILPLog.maybe_create_student_ilp_log("UPDATE", opts)
  end

  @doc """
  Deletes a student_ilp.

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> delete_student_ilp(student_ilp)
      {:ok, %StudentILP{}}

      iex> delete_student_ilp(student_ilp)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_ilp(%StudentILP{} = student_ilp, opts \\ []) do
    Repo.delete(student_ilp)
    |> ILPLog.maybe_create_student_ilp_log("DELETE", opts)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_ilp changes.

  ## Examples

      iex> change_student_ilp(student_ilp)
      %Ecto.Changeset{data: %StudentILP{}}

  """
  def change_student_ilp(%StudentILP{} = student_ilp, attrs \\ %{}) do
    StudentILP.changeset(student_ilp, attrs)
  end

  @doc """
  List students with ILP info.

  Results are ordered by student name.

  ## Options

  - `:classes_ids` - filter results by classes
  - `:preload_student_tags`

  ## Examples

      iex> list_students_and_ilps(1, 2, 3)
      [{%Student{}, %StudentILP{}}, ...]

  """
  @spec list_students_and_ilps(
          school_id :: pos_integer(),
          cycle_id :: pos_integer(),
          ilp_template_id :: pos_integer(),
          opts :: Keyword.t()
        ) :: [{Student.t(), StudentILP.t() | nil}]
  def list_students_and_ilps(school_id, cycle_id, ilp_template_id, opts \\ []) do
    students_ilps_map =
      from(
        ilp in StudentILP,
        where: ilp.cycle_id == ^cycle_id,
        where: ilp.template_id == ^ilp_template_id
      )
      |> Repo.all()
      |> Enum.map(&{&1.student_id, &1})
      |> Enum.into(%{})

    from(
      s in Student,
      where: s.school_id == ^school_id,
      where: is_nil(s.deactivated_at),
      order_by: s.name
    )
    |> apply_list_students_and_ilps_opts(opts)
    |> Repo.all()
    |> Enum.map(fn student ->
      {student, Map.get(students_ilps_map, student.id)}
    end)
  end

  defp apply_list_students_and_ilps_opts(queryable, []), do: queryable

  defp apply_list_students_and_ilps_opts(queryable, [{:classes_ids, classes_ids} | opts]) do
    from(
      s in queryable,
      join: c in assoc(s, :classes),
      where: c.id in ^classes_ids,
      group_by: s.id
    )
    |> apply_list_students_and_ilps_opts(opts)
  end

  defp apply_list_students_and_ilps_opts(queryable, [{:preload_student_tags, true} | opts]) do
    from(
      s in queryable,
      preload: [:tags]
    )
    |> apply_list_students_and_ilps_opts(opts)
  end

  defp apply_list_students_and_ilps_opts(queryable, [_ | opts]),
    do: apply_list_students_and_ilps_opts(queryable, opts)

  @doc """
  List classes with ILP metrics.

  Classes are ordered by year id.

  Deactivated students are excluded from count.

  ## Examples

      iex> list_ilp_classes_metrics(1, 2, 3)
      [{%Class{}, 3, 2}, ...]

  """
  @spec list_ilp_classes_metrics(
          school_id :: pos_integer(),
          cycle_id :: pos_integer(),
          ilp_template_id :: pos_integer()
        ) :: [{Class.t(), students_count :: integer(), ilp_count :: integer()}]
  def list_ilp_classes_metrics(school_id, cycle_id, ilp_template_id) do
    from(
      c in Class,
      left_join: y in assoc(c, :years),
      left_join: s in assoc(c, :students),
      on: is_nil(s.deactivated_at),
      left_join: ilp in assoc(s, :ilps),
      on: ilp.template_id == ^ilp_template_id and ilp.cycle_id == ^cycle_id,
      select: {c, count(s.id, :distinct), count(ilp.id, :distinct)},
      group_by: c.id,
      where: c.school_id == ^school_id and c.cycle_id == ^cycle_id,
      order_by: [asc_nulls_last: min(y.id)]
    )
    |> Repo.all()
  end

  @doc """
  Check if student has shared ILP for given cycle.
  """
  @spec student_has_ilp_for_cycle?(
          student_id :: pos_integer(),
          cycle_id :: pos_integer(),
          :shared_with_student | :shared_with_guardians
        ) :: boolean()
  def student_has_ilp_for_cycle?(student_id, cycle_id, shared_with) do
    shared_cond =
      case shared_with do
        :shared_with_student -> dynamic([ilp], ilp.is_shared_with_student)
        :shared_with_guardians -> dynamic([ilp], ilp.is_shared_with_guardians)
      end

    from(
      ilp in StudentILP,
      where: ilp.student_id == ^student_id,
      where: ilp.cycle_id == ^cycle_id,
      where: ^shared_cond
    )
    |> Repo.exists?()
  end

  @doc """
  Revise a student ILP using AI.

  ### Testing

  We use `open_ai_responses_module` as argument to allow mocking in tests.

  View https://blog.appsignal.com/2023/04/11/an-introduction-to-mocking-tools-for-elixir.html for reference.

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> revise_student_ilp(1, 2, 3)
      {:ok, %StudentILP{}}

  """
  @spec revise_student_ilp(
          StudentILP.t(),
          ILPTemplate.t(),
          age :: integer(),
          opts :: Keyword.t(),
          open_ai_responses_module :: any()
        ) ::
          {:ok, StudentILP.t()} | {:error, any()}
  def revise_student_ilp(
        %StudentILP{} = student_ilp,
        %ILPTemplate{ai_layer: %ILPTemplateAILayer{}} = template,
        age,
        opts \\ [],
        open_ai_responses_module \\ ExOpenAI.Responses
      ) do
    user_input_content =
      student_ilp_to_text(
        student_ilp,
        template,
        "review the ILP for a student with age #{age}.\n"
      )

    input =
      [
        %ExOpenAI.Components.EasyInputMessage{
          content: "Formatting re-enabled",
          role: :developer,
          type: :message
        },
        %ExOpenAI.Components.EasyInputMessage{
          content: template.ai_layer.revision_instructions,
          role: :developer,
          type: :message
        },
        %ExOpenAI.Components.EasyInputMessage{
          content: user_input_content,
          role: :user,
          type: :message
        }
      ]

    case open_ai_responses_module.create_response(input, template.ai_layer.model) do
      {:ok, %ExOpenAI.Components.Response{} = response} ->
        %{
          content: [
            %{
              text: revision
            }
          ]
        } =
          response.output
          |> Enum.find(&(&1[:type] == "message" && &1[:role] == "assistant"))

        student_ilp
        |> StudentILP.ai_changeset(%{
          ai_revision: revision,
          last_ai_revision_input: user_input_content,
          ai_revision_datetime: DateTime.utc_now()
        })
        |> Repo.update()
        |> ILPLog.maybe_create_student_ilp_log("UPDATE", opts)

      error ->
        error
    end
  end

  @doc """
  Convert the given student ILP to text.
  Useful for using ILPs in LLMs prompts.
  ### Required preloads
  - `student_ilp` - entries
  - `template` - sections and components
  ## Examples
      iex> student_ilp_to_text(student_ilp)
      "ILP as text"
  """
  @spec student_ilp_to_text(
          StudentILP.t(),
          ILPTemplate.t(),
          initial_text :: binary()
        ) :: binary()
  def student_ilp_to_text(
        %StudentILP{} = student_ilp,
        %ILPTemplate{} = template,
        initial_text \\ ""
      ) do
    component_entry_map =
      template.sections
      |> Enum.flat_map(& &1.components)
      |> Enum.map(fn component ->
        {
          component.id,
          Enum.find(student_ilp.entries, &(&1.component_id == component.id))
        }
      end)
      |> Enum.filter(fn {_component_id, entry} -> entry end)
      |> Enum.into(%{})

    Enum.reduce(
      template.sections,
      initial_text,
      fn section, acc ->
        section_components =
          Enum.map(section.components, fn component ->
            entry = component_entry_map[component.id]
            "###{component.name}\n#{entry.description}"
          end)

        acc <> "##{section.name}\n" <> Enum.join(section_components, "\n") <> "\n"
      end
    )
  end

  alias Lanttern.ILP.ILPComment

  @doc """
  Returns the list of ilp_comments.

  ## Examples

      iex> list_ilp_comments()
      [%ILPComment{}, ...]

  """
  def list_ilp_comments do
    Repo.all(ILPComment)
  end

  def list_ilp_comments_by_student_ilp(student_ilp_id) do
    from(
      c in ILPComment,
      join: p in assoc(c, :owner),
      left_join: s in assoc(p, :student),
      left_join: sm in assoc(p, :staff_member),
      left_join: gos in assoc(p, :guardian_of_student),
      left_join: a in assoc(c, :attachments),
      where: c.student_ilp_id == ^student_ilp_id,
      order_by: [asc: c.inserted_at],
      preload: [
        {:attachments, a},
        {:owner,
         {p,
          [
            student: s,
            staff_member: sm,
            guardian_of_student: gos
          ]}}
      ]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single ilp_comment or nil.

  ## Options

  - `:owner_id` - filter results by owner(Profile)

  """
  def get_ilp_comment(id, opts \\ []) do
    dynamic_filter =
      Enum.reduce(opts, dynamic(true), fn
        {:owner_id, owner_id}, acc ->
          dynamic([c], ^acc and c.owner_id == ^owner_id)

        {_, _}, dynamic ->
          dynamic
      end)

    from(
      c in ILPComment,
      where: c.id == ^id,
      where: ^dynamic_filter
    )
    |> Repo.one()
  end

  @doc """
  Creates a ilp_comment.

  ## Options

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> create_ilp_comment(%{field: value})
      {:ok, %ILPComment{}}

      iex> create_ilp_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ilp_comment(attrs, opts \\ []) do
    %ILPComment{}
    |> ILPComment.changeset(attrs)
    |> Repo.insert()
    |> ILPLog.maybe_create_ilp_comment_log(:CREATE, opts)
  end

  @doc """
  Updates a ilp_comment.

  ## Options

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> update_ilp_comment(ilp_comment, %{field: new_value}, log_profile_id)
      {:ok, %ILPComment{}}

      iex> update_ilp_comment(ilp_comment, %{field: bad_value}, log_profile_id)
      {:error, %Ecto.Changeset{}}

  """
  def update_ilp_comment(%ILPComment{} = ilp_comment, attrs, opts \\ []) do
    ilp_comment
    |> ILPComment.changeset(attrs)
    |> Repo.update()
    |> ILPLog.maybe_create_ilp_comment_log(:UPDATE, opts)
  end

  @doc """
  Deletes a ilp_comment.

  ## Options

  - `:log_profile_id` - logs the operation, linked to given profile

  """
  def delete_ilp_comment(%ILPComment{} = ilp_comment, opts \\ []) do
    ilp_comment
    |> Repo.delete()
    |> ILPLog.maybe_create_ilp_comment_log(:DELETE, opts)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ilp_comment changes.

  ## Examples

      iex> change_ilp_comment(ilp_comment)
      %Ecto.Changeset{data: %ILPComment{}}

  """
  def change_ilp_comment(%ILPComment{} = ilp_comment, attrs \\ %{}) do
    ILPComment.changeset(ilp_comment, attrs)
  end

  alias Lanttern.ILP.ILPCommentAttachment

  @doc """
  Returns the list of ilp_comment_attachments.

  ## Examples

      iex> list_ilp_comment_attachments()
      [%ILPCommentAttachment{}, ...]

  """
  def list_ilp_comment_attachments do
    Repo.all(ILPCommentAttachment)
  end

  def list_ilp_comment_attachments(ilp_comment_id) do
    ILPCommentAttachment
    |> where([c], c.ilp_comment_id == ^ilp_comment_id)
    |> Repo.all()
  end

  @doc """
  Gets a single ilp_comment_attachment.

  Raises `Ecto.NoResultsError` if the Ilp comment attachment does not exist.

  ## Examples

      iex> get_ilp_comment_attachment!(123)
      %ILPCommentAttachment{}

      iex> get_ilp_comment_attachment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ilp_comment_attachment!(id), do: Repo.get!(ILPCommentAttachment, id)

  @doc """
  Creates a ilp_comment_attachment.

  ## Examples

      iex> create_ilp_comment_attachment(%{field: value})
      {:ok, %ILPCommentAttachment{}}

      iex> create_ilp_comment_attachment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ilp_comment_attachment(attrs \\ %{}) do
    %ILPCommentAttachment{}
    |> ILPCommentAttachment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ilp_comment_attachment.

  ## Examples

      iex> update_ilp_comment_attachment(ilp_comment_attachment, %{field: new_value})
      {:ok, %ILPCommentAttachment{}}

      iex> update_ilp_comment_attachment(ilp_comment_attachment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ilp_comment_attachment(%ILPCommentAttachment{} = ilp_comment_attachment, attrs) do
    ilp_comment_attachment
    |> ILPCommentAttachment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ilp_comment_attachment.

  ## Examples

      iex> delete_ilp_comment_attachment(ilp_comment_attachment)
      {:ok, %ILPCommentAttachment{}}

      iex> delete_ilp_comment_attachment(ilp_comment_attachment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ilp_comment_attachment(%ILPCommentAttachment{} = ilp_comment_attachment) do
    Repo.delete(ilp_comment_attachment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ilp_comment_attachment changes.

  ## Examples

      iex> change_ilp_comment_attachment(ilp_comment_attachment)
      %Ecto.Changeset{data: %ILPCommentAttachment{}}

  """
  def change_ilp_comment_attachment(
        %ILPCommentAttachment{} = ilp_comment_attachment,
        attrs \\ %{}
      ) do
    ILPCommentAttachment.changeset(ilp_comment_attachment, attrs)
  end

  @doc """
  Update ILP Comment attachments positions based on ids list order.

  ## Examples

  iex> update_ilp_comment_attachment_positions([3, 2, 1])
  :ok

  """
  @spec update_ilp_comment_attachment_positions([pos_integer()]) :: :ok | {:error, String.t()}
  def update_ilp_comment_attachment_positions(ilp_comment_attachment),
    do: update_positions(ILPCommentAttachment, ilp_comment_attachment)
end
