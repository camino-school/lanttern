defmodule Lanttern.Identity.Scope do
  @moduledoc """
  The scope data structure for maintaining request/session information.

  A lightweight scope contains only essential identifiers and permissions
  for the current user and their profile. This is used to properly scope
  database operations for security and data access control without carrying
  full structs in memory.
  """

  alias Lanttern.Identity.Profile
  alias Lanttern.Identity.User

  @type t :: %__MODULE__{
          user_id: pos_integer() | nil,
          profile_id: pos_integer() | nil,
          profile_type: String.t() | nil,
          staff_member_id: pos_integer() | nil,
          student_id: pos_integer() | nil,
          school_id: pos_integer() | nil,
          permissions: [String.t()]
        }

  defstruct user_id: nil,
            profile_id: nil,
            profile_type: nil,
            staff_member_id: nil,
            student_id: nil,
            school_id: nil,
            permissions: []

  @doc """
  Creates a scope for the given user.

  Returns `nil` if the user is `nil`.

  ## Examples

      iex> for_user(%User{id: 1, current_profile: %Profile{id: 2, school_id: 3}})
      %Scope{user_id: 1, profile_id: 2, school_id: 3}

      iex> for_user(nil)
      nil

  """
  @spec for_user(User.t() | nil) :: t() | nil
  def for_user(%User{id: user_id, current_profile: %Profile{} = profile}) do
    %__MODULE__{
      user_id: user_id,
      profile_id: profile.id,
      profile_type: profile.type,
      staff_member_id: profile.staff_member_id,
      student_id: profile.student_id || profile.guardian_of_student_id,
      school_id: profile.school_id,
      permissions: profile.permissions || []
    }
  end

  def for_user(%User{id: user_id}) do
    %__MODULE__{
      user_id: user_id,
      profile_id: nil,
      profile_type: nil,
      staff_member_id: nil,
      student_id: nil,
      school_id: nil,
      permissions: []
    }
  end

  def for_user(nil), do: nil

  @doc """
  Adds a permission to the scope.

  If the permission already exists, the scope is returned unchanged.

  ## Examples

      iex> put_permission(%Scope{permissions: []}, "manage_posts")
      %Scope{permissions: ["manage_posts"]}

      iex> put_permission(%Scope{permissions: ["view_posts"]}, "manage_posts")
      %Scope{permissions: ["view_posts", "manage_posts"]}

      iex> put_permission(%Scope{permissions: ["manage_posts"]}, "manage_posts")
      %Scope{permissions: ["manage_posts"]}

  """
  @spec put_permission(t(), String.t()) :: t()
  def put_permission(%__MODULE__{permissions: permissions} = scope, permission)
      when is_binary(permission) do
    if permission in permissions do
      scope
    else
      %{scope | permissions: [permission | permissions]}
    end
  end

  @doc """
  Checks if the scope matches the given profile.

  ## Examples

      iex> matches_profile?(%Scope{profile_id: 1}, 1)
      true

      iex> matches_profile?(%Scope{profile_id: 1}, 2)
      false

      iex> matches_profile?(nil, 1)
      false

  """
  @spec matches_profile?(t() | nil, pos_integer()) :: boolean()
  def matches_profile?(%__MODULE__{profile_id: profile_id}, profile_id)
      when is_integer(profile_id),
      do: true

  def matches_profile?(_scope, _profile_id), do: false

  @doc """
  Checks if the scope has a specific permission.

  ## Examples

      iex> has_permission?(%Scope{permissions: ["manage_posts"]}, "manage_posts")
      true

      iex> has_permission?(%Scope{permissions: []}, "manage_posts")
      false

      iex> has_permission?(nil, "manage_posts")
      false

  """
  @spec has_permission?(t() | nil, String.t()) :: boolean()
  def has_permission?(%__MODULE__{permissions: permissions}, permission)
      when is_list(permissions) do
    permission in permissions
  end

  def has_permission?(_scope, _permission), do: false

  @doc """
  Checks if the scope belongs to a specific school.

  ## Examples

      iex> belongs_to_school?(%Scope{school_id: 1}, 1)
      true

      iex> belongs_to_school?(%Scope{school_id: 1}, 2)
      false

      iex> belongs_to_school?(nil, 1)
      false

  """
  @spec belongs_to_school?(t() | nil, pos_integer()) :: boolean()
  def belongs_to_school?(%__MODULE__{school_id: school_id}, school_id) when is_integer(school_id),
    do: true

  def belongs_to_school?(_scope, _school_id), do: false

  @doc """
  Checks if the scope is for a specific profile type.

  Valid types: "student", "staff", "guardian"

  ## Examples

      iex> profile_type?(%Scope{profile_type: "staff"}, "staff")
      true

      iex> profile_type?(%Scope{profile_type: "staff"}, "student")
      false

      iex> profile_type?(nil, "staff")
      false

  """
  @spec profile_type?(t() | nil, String.t()) :: boolean()
  def profile_type?(%__MODULE__{profile_type: profile_type}, profile_type)
      when is_binary(profile_type),
      do: true

  def profile_type?(_scope, _profile_type), do: false

  @doc """
  Checks if the scope is for a specific staff member.

  ## Examples

      iex> staff_member?(%Scope{profile_type: "staff", staff_member_id: 1}, 1)
      true

      iex> staff_member?(%Scope{profile_type: "staff", staff_member_id: 2}, 1)
      false

      iex> staff_member?(%Scope{profile_type: "student", staff_member_id: 1}, 1)
      false

      iex> staff_member?(nil, 1)
      false

  """
  @spec staff_member?(t() | nil, pos_integer()) :: boolean()
  def staff_member?(%__MODULE__{profile_type: "staff", staff_member_id: id}, id)
      when is_integer(id),
      do: true

  def staff_member?(_scope, _staff_member_id), do: false
end
