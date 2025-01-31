defmodule Lanttern.StudentsRecords.StudentRecord do
  @moduledoc """
  The `StudentRecord` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Repo

  alias Lanttern.StudentsRecords.AssigneeRelationship
  alias Lanttern.StudentsRecords.StudentRecordClassRelationship
  alias Lanttern.StudentsRecords.StudentRecordRelationship
  alias Lanttern.StudentsRecords.StudentRecordStatus
  alias Lanttern.StudentsRecords.Tag
  alias Lanttern.StudentsRecords.TagRelationship
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.School
  alias Lanttern.Schools.StaffMember
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t(),
          internal_notes: String.t(),
          date: Date.t(),
          time: Time.t(),
          closed_at: DateTime.t(),
          duration_until_close: Duration.t(),
          shared_with_school: boolean(),
          students: [Student.t()],
          students_ids: [pos_integer()],
          created_by_staff_member: StaffMember.t(),
          created_by_staff_member_id: pos_integer(),
          closed_by_staff_member: StaffMember.t(),
          closed_by_staff_member_id: pos_integer(),
          classes: [Class.t()],
          classes_ids: [pos_integer()],
          school: School.t(),
          school_id: pos_integer(),
          status: StudentRecordStatus.t(),
          status_id: pos_integer(),
          tags: [Tag.t()],
          tags_ids: [pos_integer()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "students_records" do
    field :name, :string
    field :description, :string
    field :internal_notes, :string
    field :date, :date
    field :time, :time
    field :closed_at, :utc_datetime
    # duration_until_close is generated
    field :duration_until_close, :duration, read_after_writes: true
    field :shared_with_school, :boolean, default: false

    field :students_ids, {:array, :id}, virtual: true
    field :classes_ids, {:array, :id}, virtual: true
    field :assignees_ids, {:array, :id}, virtual: true
    field :tags_ids, {:array, :id}, virtual: true

    belongs_to :school, School
    belongs_to :created_by_staff_member, StaffMember
    belongs_to :closed_by_staff_member, StaffMember
    belongs_to :status, StudentRecordStatus

    has_many :tags_relationships, TagRelationship, on_replace: :delete
    has_many :students_relationships, StudentRecordRelationship, on_replace: :delete
    has_many :classes_relationships, StudentRecordClassRelationship, on_replace: :delete
    has_many :assignees_relationships, AssigneeRelationship, on_replace: :delete

    many_to_many :tags, Tag,
      join_through: "students_records_tags",
      preload_order: [asc: :position]

    many_to_many :students, Student,
      join_through: "students_students_records",
      preload_order: [asc: :name]

    many_to_many :classes, Class, join_through: "students_records_classes"

    many_to_many :assignees, StaffMember,
      join_through: "students_records_assignees",
      preload_order: [asc: :name]

    timestamps()
  end

  @doc false
  def changeset(student_record, attrs) do
    student_record
    |> cast(attrs, [
      :name,
      :description,
      :internal_notes,
      :date,
      :time,
      # :closed_by_staff_member_id, # handled by update_changeset_closed_fields
      # :closed_at, # handled by update_changeset_closed_fields
      :shared_with_school,
      :school_id,
      :created_by_staff_member_id,
      :status_id,
      :tags_ids,
      :students_ids,
      :classes_ids,
      :assignees_ids
    ])
    |> validate_required([
      :description,
      :date,
      :school_id,
      :created_by_staff_member_id,
      :status_id
    ])
    |> cast_and_validate_students()
    |> cast_and_validate_tags()
    |> cast_classes()
    |> cast_assignees()
    |> check_constraint(:closed_by_staff_member_id,
      name: :closed_by_staff_member_id_required_when_closed,
      message: gettext("Closed by staff member field in required when record is closed")
    )
    |> check_constraint(:closed_by_staff_member_id,
      name: :closed_by_staff_member_id_only_allowed_when_closed,
      message: gettext("Closed by staff member is allowed only when record is closed")
    )
  end

  def cast_and_validate_students(changeset) do
    changeset =
      cast_students(
        changeset,
        get_change(changeset, :students_ids)
      )

    case get_field(changeset, :students_relationships) do
      [] ->
        add_error(changeset, :students_ids, gettext("At least 1 student is required"))

      _ ->
        changeset
    end
  end

  defp cast_students(changeset, students_ids) when is_list(students_ids) do
    school_id = get_field(changeset, :school_id)

    students_relationships_params =
      Enum.map(students_ids, &%{student_id: &1, school_id: school_id})

    changeset
    |> put_change(:students_relationships, students_relationships_params)
    |> cast_assoc(:students_relationships)
  end

  defp cast_students(changeset, _), do: changeset

  def cast_and_validate_tags(changeset) do
    changeset =
      cast_tags(
        changeset,
        get_change(changeset, :tags_ids)
      )

    case get_field(changeset, :tags_relationships) do
      [] ->
        add_error(changeset, :tags_ids, gettext("At least 1 tag is required"))

      _ ->
        changeset
    end
  end

  defp cast_tags(changeset, tags_ids) when is_list(tags_ids) do
    school_id = get_field(changeset, :school_id)

    tags_relationships_params =
      Enum.map(tags_ids, &%{tag_id: &1, school_id: school_id})

    changeset
    |> put_change(:tags_relationships, tags_relationships_params)
    |> cast_assoc(:tags_relationships)
  end

  defp cast_tags(changeset, _), do: changeset

  defp cast_classes(changeset) do
    case get_change(changeset, :classes_ids) do
      classes_ids when is_list(classes_ids) ->
        school_id = get_field(changeset, :school_id)

        classes_relationships_params =
          Enum.map(classes_ids, &%{class_id: &1, school_id: school_id})

        changeset
        |> put_change(:classes_relationships, classes_relationships_params)
        |> cast_assoc(:classes_relationships)

      _ ->
        changeset
    end
  end

  defp cast_assignees(changeset) do
    case get_change(changeset, :assignees_ids) do
      assignees_ids when is_list(assignees_ids) ->
        school_id = get_field(changeset, :school_id)

        assignees_relationships_params =
          Enum.map(assignees_ids, &%{staff_member_id: &1, school_id: school_id})

        changeset
        |> put_change(:assignees_relationships, assignees_relationships_params)
        |> cast_assoc(:assignees_relationships)

      _ ->
        changeset
    end
  end

  @doc """
  Handles the `closed_at` and `closed_by_staff_member_id` field based on status.

  Relevant only for updates, as records created with `is_closed` statuses are
  considered "closed on creation" (`closed_at` = `inserted_at` and
  `closed_by_staff_member_id` = `created_by_staff_member_id`).
  """

  @spec update_changeset_closed_fields(Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()

  def update_changeset_closed_fields(changeset, params) do
    get_changeset_status(changeset)
    |> case do
      nil ->
        changeset

      %{is_closed: true} ->
        changeset
        |> put_change(:closed_at, DateTime.utc_now(:second))
        |> put_change(:closed_by_staff_member_id, params["closed_by_staff_member_id"])

      %{is_closed: false} ->
        changeset
        |> put_change(:closed_at, nil)
        |> put_change(:closed_by_staff_member_id, nil)
    end
  end

  defp get_changeset_status(changeset) do
    # we use get_field (instead of get_change) because even
    # if status id is not changed, we want to validate the status
    # on updates
    case Ecto.Changeset.get_field(changeset, :status_id) do
      nil -> nil
      status_id -> Repo.get(StudentRecordStatus, status_id)
    end
  end
end
