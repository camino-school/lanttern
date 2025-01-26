defmodule Lanttern.Identity do
  @moduledoc """
  The Identity context.
  """

  import Ecto.Query, warn: false

  import Lanttern.RepoHelpers
  alias Lanttern.Repo
  alias Lanttern.Identity.User
  alias Lanttern.Identity.UserToken
  alias Lanttern.Identity.UserNotifier
  alias Lanttern.Identity.Profile
  alias Lanttern.Personalization
  alias Lanttern.Schools.School

  ## Database getters

  @doc """
  Returns the list of users.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users(opts \\ []) do
    User
    |> Repo.all()
    |> maybe_preload(opts)
  end

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Updates an user email.

  This function should be use only in admin (and maybe it should be removed
  or refactored in the near future, adding more security guards).

  ## Examples

      iex> admin_update_user_email(user, %{"email => "email@blah.com"})
      {:ok, %User{}}

      iex> admin_update_user_email(user, %{"email => "bad_email@blah.com"})
      {:error, %Ecto.Changeset{}}
  """
  def admin_update_user_email(user, params) do
    user
    |> User.email_changeset(params)
    |> Repo.update()
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Updates the user current profile id.

  ## Examples

      iex> update_user_current_profile_id(user, valid_profile_id)
      {:ok, %User{}}

      iex> update_user_current_profile_id(user, invalid_profile_id)
      {:error, %Ecto.Changeset{}}

  """
  def update_user_current_profile_id(user, profile_id) do
    user
    |> User.current_profile_id_changeset(%{current_profile_id: profile_id})
    |> Repo.update()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  Preloads `current_profile`.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)

    query
    |> Repo.one()
    |> Repo.preload(
      current_profile: [
        staff_member: [:school],
        student: [:school],
        guardian_of_student: [:school]
      ]
    )
    |> case do
      nil ->
        nil

      user ->
        user
        |> Map.update!(:current_profile, &build_flat_profile/1)
        |> Map.update!(:current_profile, &add_profile_settings/1)
    end
  end

  defp build_flat_profile(%{type: "staff", staff_member: staff_member} = profile) do
    profile
    |> Map.put(:name, staff_member.name)
    |> Map.put(:role, staff_member.role)
    |> Map.put(:profile_picture_url, staff_member.profile_picture_url)
    |> Map.put(:school_id, staff_member.school.id)
    |> Map.put(:school_name, staff_member.school.name)
  end

  defp build_flat_profile(%{type: "student", student: student} = profile) do
    profile
    |> Map.put(:name, student.name)
    |> Map.put(:school_id, student.school.id)
    |> Map.put(:school_name, student.school.name)
  end

  defp build_flat_profile(%{type: "guardian", guardian_of_student: student} = profile) do
    profile
    |> Map.put(:name, student.name)
    |> Map.put(:school_id, student.school.id)
    |> Map.put(:school_name, student.school.name)
  end

  defp build_flat_profile(profile), do: profile

  defp add_profile_settings(%{id: profile_id} = profile) do
    profile_settings =
      Personalization.get_profile_settings(profile_id, preloads: :current_school_cycle) || %{}

    permissions = Map.get(profile_settings, :permissions, [])
    current_school_cycle = Map.get(profile_settings, :current_school_cycle)

    profile
    |> Map.put(:permissions, permissions)
    |> Map.put(:current_school_cycle, current_school_cycle)
  end

  defp add_profile_settings(profile), do: profile

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Updates the user privacy policy accepted fields.

  ## Examples

      iex> update_user_privacy_policy_accepted(user, "metadata")
      {:ok, %User{}}

      iex> update_user_privacy_policy_accepted(user, "invalid metadata")
      {:error, %Ecto.Changeset{}}
  """
  def update_user_privacy_policy_accepted(user, metadata) do
    # append metadata to existing metadata
    metadata =
      case user.privacy_policy_accepted_meta do
        nil -> metadata
        existing_metadata -> "#{existing_metadata}\n#{metadata}"
      end

    user
    |> User.privacy_policy_accepted_changeset(metadata)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  This function should be used only in admin (and maybe it should be removed
  or refactored in the near future, adding more security guards).

  ## Examples

      iex> admin_delete_user(user)
      {:ok, %User{}}

      iex> admin_delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def admin_delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns the list of profiles.

  ### Options:

  `:preloads` – preloads associated data
  `:user_id` – filter profiles by user_id
  `:type` – filter profiles by type
  `:only_active` - removes deactivated staff members from the list
  `:load_virtual_fields` - load profile virtual fields name, role, profile_picture_url, school_id, school_name

  ## Examples

      iex> list_profiles()
      [%Profile{}, ...]

  """
  def list_profiles(opts \\ []) do
    Profile
    |> apply_list_profiles_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_profiles_opts(queryable, []), do: queryable

  defp apply_list_profiles_opts(queryable, [{:user_id, user_id} | opts]) do
    from(p in queryable, where: p.user_id == ^user_id)
    |> apply_list_profiles_opts(opts)
  end

  defp apply_list_profiles_opts(queryable, [{:type, type} | opts]) do
    from(p in queryable, where: p.type == ^type)
    |> apply_list_profiles_opts(opts)
  end

  defp apply_list_profiles_opts(queryable, [{:only_active, true} | opts]) do
    from(
      p in queryable,
      left_join: sm in assoc(p, :staff_member),
      where: is_nil(sm) or is_nil(sm.deactivated_at)
    )
    |> apply_list_profiles_opts(opts)
  end

  defp apply_list_profiles_opts(queryable, [{:load_virtual_fields, true} | opts]) do
    from(
      p in queryable,
      left_join: sm in assoc(p, :staff_member),
      left_join: s in assoc(p, :student),
      left_join: gos in assoc(p, :guardian_of_student),
      left_join: sch in School,
      on: sm.school_id == sch.id or s.school_id == sch.id or gos.school_id == sch.id,
      order_by: [asc: sm.name |> coalesce(s.name) |> coalesce(gos.name), asc: p.type],
      select: %{
        p
        | name: sm.name |> coalesce(s.name) |> coalesce(gos.name),
          role: sm.role,
          profile_picture_url: sm.profile_picture_url,
          school_id: sch.id,
          school_name: sch.name
      }
    )
    |> apply_list_profiles_opts(opts)
  end

  defp apply_list_profiles_opts(queryable, [_ | opts]),
    do: apply_list_profiles_opts(queryable, opts)

  @doc """
  Gets a single profile.

  Raises `Ecto.NoResultsError` if the Profile does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_profile!(123)
      %Profile{}

      iex> get_profile!(456)
      ** (Ecto.NoResultsError)

  """
  def get_profile!(id, opts \\ []) do
    Profile
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a profile.

  ## Examples

      iex> create_profile(%{field: value})
      {:ok, %Profile{}}

      iex> create_profile(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_profile(attrs \\ %{}) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a profile.

  ## Examples

      iex> update_profile(profile, %{field: new_value})
      {:ok, %Profile{}}

      iex> update_profile(profile, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_profile(%Profile{} = profile, attrs) do
    profile
    |> Profile.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a profile.

  ## Examples

      iex> delete_profile(profile)
      {:ok, %Profile{}}

      iex> delete_profile(profile)
      {:error, %Ecto.Changeset{}}

  """
  def delete_profile(%Profile{} = profile) do
    Repo.delete(profile)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking profile changes.

  ## Examples

      iex> change_profile(profile)
      %Ecto.Changeset{data: %Profile{}}

  """
  def change_profile(%Profile{} = profile, attrs \\ %{}) do
    Profile.changeset(profile, attrs)
  end
end
