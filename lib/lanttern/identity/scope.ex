defmodule Lanttern.Identity.Scope do
  @moduledoc """
  The scope data structure for maintaining request/session information.

  A scope contains information about the current user and their profile,
  including school association, permissions, and role. This is used to
  properly scope database operations for security and data access control.
  """

  alias Lanttern.Identity.Profile
  alias Lanttern.Identity.User

  @type t :: %__MODULE__{
          user: User.t() | nil,
          profile: Profile.t() | nil,
          school_id: pos_integer() | nil,
          permissions: [String.t()],
          profile_type: String.t() | nil,
          role: String.t() | nil
        }

  defstruct user: nil,
            profile: nil,
            school_id: nil,
            permissions: [],
            profile_type: nil,
            role: nil

  @doc """
  Creates a scope for the given user.

  Returns `nil` if the user is `nil`.

  ## Examples

      iex> for_user(%User{current_profile: %Profile{school_id: 1}})
      %Scope{user: %User{}, profile: %Profile{}, school_id: 1}

      iex> for_user(nil)
      nil

  """
  @spec for_user(User.t() | nil) :: t() | nil
  def for_user(%User{current_profile: %Profile{} = profile} = user) do
    %__MODULE__{
      user: user,
      profile: profile,
      school_id: profile.school_id,
      permissions: profile.permissions || [],
      profile_type: profile.type,
      role: profile.role
    }
  end

  def for_user(%User{} = user) do
    %__MODULE__{
      user: user,
      profile: nil,
      school_id: nil,
      permissions: [],
      profile_type: nil,
      role: nil
    }
  end

  def for_user(nil), do: nil

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
  Checks if the scope is for a root admin user.

  ## Examples

      iex> root_admin?(%Scope{user: %User{is_root_admin: true}})
      true

      iex> root_admin?(%Scope{user: %User{is_root_admin: false}})
      false

      iex> root_admin?(nil)
      false

  """
  @spec root_admin?(t() | nil) :: boolean()
  def root_admin?(%__MODULE__{user: %User{is_root_admin: true}}), do: true
  def root_admin?(_scope), do: false

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
end
