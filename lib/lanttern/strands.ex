defmodule Lanttern.Strands do
  @moduledoc """
  The Strands context.
  """

  import Ecto.Query, warn: false

  import Lanttern.RepoHelpers,
    only: [maybe_preload: 2, set_position_in_attrs: 2, update_positions: 2]

  alias Lanttern.Repo

  alias Lanttern.Identity.Scope
  alias Lanttern.Schools.Class
  alias Lanttern.Strands.ClassAssignment
  alias Lanttern.Strands.StrandCurriculumItem

  @doc """
  Subscribes to scoped notifications about any strand_curriculum_item changes.

  The broadcasted messages match the pattern:

    * {:created, %StrandCurriculumItem{}}
    * {:updated, %StrandCurriculumItem{}}
    * {:deleted, %StrandCurriculumItem{}}

  """
  def subscribe_strand_curriculum_items(%Scope{} = scope) do
    key = scope.school_id

    Phoenix.PubSub.subscribe(Lanttern.PubSub, "school:#{key}:strand_curriculum_items")
  end

  defp broadcast_strand_curriculum_item(%Scope{} = scope, message) do
    key = scope.school_id

    Phoenix.PubSub.broadcast(Lanttern.PubSub, "school:#{key}:strand_curriculum_items", message)
  end

  @doc """
  Returns the list of strand_curriculum_items for a given strand, ordered by position.

  This queries the explicit `strand_curriculum_items` join table. For curriculum items
  derived from strand assessment points (strand goals), see
  `Lanttern.Curricula.list_strand_curriculum_items/2`.

  ## Options

  - `:preloads` - preloads to apply

  ## Examples

      iex> list_strand_curriculum_items(scope, strand_id)
      [%StrandCurriculumItem{}, ...]

  """
  def list_strand_curriculum_items(%Scope{} = _scope, strand_id, opts \\ []) do
    from(sci in StrandCurriculumItem,
      where: sci.strand_id == ^strand_id,
      order_by: [asc: sci.position]
    )
    |> Repo.all()
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single strand_curriculum_item.

  Raises `Ecto.NoResultsError` if the Strand curriculum item does not exist.

  ## Examples

      iex> get_strand_curriculum_item!(scope, 123)
      %StrandCurriculumItem{}

      iex> get_strand_curriculum_item!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_strand_curriculum_item!(%Scope{} = _scope, id) do
    Repo.get!(StrandCurriculumItem, id)
  end

  @doc """
  Creates a strand_curriculum_item.

  ## Examples

      iex> create_strand_curriculum_item(scope, %{field: value})
      {:ok, %StrandCurriculumItem{}}

      iex> create_strand_curriculum_item(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_strand_curriculum_item(%Scope{} = scope, attrs) do
    true = Scope.profile_type?(scope, "staff")

    strand_id = Map.get(attrs, :strand_id) || Map.get(attrs, "strand_id")

    attrs =
      if strand_id do
        from(sci in StrandCurriculumItem, where: sci.strand_id == ^strand_id)
        |> set_position_in_attrs(attrs)
      else
        attrs
      end

    with {:ok, strand_curriculum_item = %StrandCurriculumItem{}} <-
           %StrandCurriculumItem{}
           |> StrandCurriculumItem.changeset(attrs)
           |> Repo.insert() do
      broadcast_strand_curriculum_item(scope, {:created, strand_curriculum_item})
      {:ok, strand_curriculum_item}
    end
  end

  @doc """
  Updates a strand_curriculum_item.

  ## Examples

      iex> update_strand_curriculum_item(scope, strand_curriculum_item, %{field: new_value})
      {:ok, %StrandCurriculumItem{}}

      iex> update_strand_curriculum_item(scope, strand_curriculum_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_strand_curriculum_item(
        %Scope{} = scope,
        %StrandCurriculumItem{} = strand_curriculum_item,
        attrs
      ) do
    true = Scope.profile_type?(scope, "staff")

    with {:ok, strand_curriculum_item = %StrandCurriculumItem{}} <-
           strand_curriculum_item
           |> StrandCurriculumItem.changeset(attrs)
           |> Repo.update() do
      broadcast_strand_curriculum_item(scope, {:updated, strand_curriculum_item})
      {:ok, strand_curriculum_item}
    end
  end

  @doc """
  Deletes a strand_curriculum_item.

  ## Examples

      iex> delete_strand_curriculum_item(scope, strand_curriculum_item)
      {:ok, %StrandCurriculumItem{}}

      iex> delete_strand_curriculum_item(scope, strand_curriculum_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_strand_curriculum_item(
        %Scope{} = scope,
        %StrandCurriculumItem{} = strand_curriculum_item
      ) do
    true = Scope.profile_type?(scope, "staff")

    with {:ok, strand_curriculum_item = %StrandCurriculumItem{}} <-
           Repo.delete(strand_curriculum_item) do
      broadcast_strand_curriculum_item(scope, {:deleted, strand_curriculum_item})
      {:ok, strand_curriculum_item}
    end
  end

  @doc """
  Updates positions for a list of strand_curriculum_item ids.
  """
  def update_strand_curriculum_items_positions(ids) do
    update_positions(StrandCurriculumItem, ids)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking strand_curriculum_item changes.

  ## Examples

      iex> change_strand_curriculum_item(scope, strand_curriculum_item)
      %Ecto.Changeset{data: %StrandCurriculumItem{}}

  """
  def change_strand_curriculum_item(
        %Scope{} = _scope,
        %StrandCurriculumItem{} = strand_curriculum_item,
        attrs \\ %{}
      ) do
    StrandCurriculumItem.changeset(strand_curriculum_item, attrs)
  end

  # class_assignments

  @doc """
  Returns the list of class assignments for a given strand, ordered by class name.

  Only returns assignments whose class belongs to the scope's school.
  Always preloads `:class`.

  ## Examples

      iex> list_strand_class_assignments(scope, strand_id)
      [%ClassAssignment{}, ...]

  """
  def list_strand_class_assignments(%Scope{} = scope, strand_id) do
    from(ca in ClassAssignment,
      join: c in assoc(ca, :class),
      where: ca.strand_id == ^strand_id,
      where: c.school_id == ^scope.school_id,
      order_by: c.name,
      preload: [class: c]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single class assignment.

  Only returns the assignment if the class belongs to the scope's school.
  Always preloads `:class`.

  Raises `Ecto.NoResultsError` if the class assignment does not exist.

  ## Examples

      iex> get_strand_class_assignment!(scope, 123)
      %ClassAssignment{}

      iex> get_strand_class_assignment!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_strand_class_assignment!(%Scope{} = scope, id) do
    from(ca in ClassAssignment,
      join: c in assoc(ca, :class),
      where: ca.id == ^id,
      where: c.school_id == ^scope.school_id,
      preload: [class: c]
    )
    |> Repo.one!()
  end

  @doc """
  Creates a class assignment linking a strand to a class.

  Requires a staff scope. The class must belong to the scope's school.

  ## Examples

      iex> create_strand_class_assignment(scope, %{strand_id: 1, class_id: 2})
      {:ok, %ClassAssignment{}}

      iex> create_strand_class_assignment(scope, %{})
      {:error, %Ecto.Changeset{}}

  """
  def create_strand_class_assignment(%Scope{} = scope, attrs) do
    true = Scope.profile_type?(scope, "staff")

    class_id = Map.get(attrs, :class_id) || Map.get(attrs, "class_id")

    if class_id do
      class = Repo.get!(Class, class_id)
      true = class.school_id == scope.school_id
    end

    %ClassAssignment{}
    |> ClassAssignment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a class assignment.

  Requires a staff scope. If `class_id` is changed, the new class must belong to the scope's school.

  ## Examples

      iex> update_strand_class_assignment(scope, class_assignment, %{class_id: 3})
      {:ok, %ClassAssignment{}}

      iex> update_strand_class_assignment(scope, class_assignment, %{class_id: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_strand_class_assignment(
        %Scope{} = scope,
        %ClassAssignment{} = class_assignment,
        attrs
      ) do
    true = Scope.profile_type?(scope, "staff")

    class_id =
      Map.get(attrs, :class_id) || Map.get(attrs, "class_id") || class_assignment.class_id

    class = Repo.get!(Class, class_id)
    true = class.school_id == scope.school_id

    class_assignment
    |> ClassAssignment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a class assignment.

  Requires a staff scope. The assignment's class must belong to the scope's school.

  ## Examples

      iex> delete_strand_class_assignment(scope, class_assignment)
      {:ok, %ClassAssignment{}}

  """
  def delete_strand_class_assignment(
        %Scope{} = scope,
        %ClassAssignment{} = class_assignment
      ) do
    true = Scope.profile_type?(scope, "staff")

    class = Repo.get!(Class, class_assignment.class_id)
    true = class.school_id == scope.school_id

    Repo.delete(class_assignment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking class assignment changes.

  ## Examples

      iex> change_strand_class_assignment(scope, class_assignment)
      %Ecto.Changeset{data: %ClassAssignment{}}

  """
  def change_strand_class_assignment(
        %Scope{} = _scope,
        %ClassAssignment{} = class_assignment,
        attrs \\ %{}
      ) do
    ClassAssignment.changeset(class_assignment, attrs)
  end
end
