defmodule Lanttern.Identity do
  @moduledoc """
  The Identity context.
  """

  import Ecto.Query, warn: false

  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.Identity.LoginCode
  alias Lanttern.Identity.Profile
  alias Lanttern.Identity.User
  alias Lanttern.Identity.UserNotifier
  alias Lanttern.Identity.UserToken
  alias Lanttern.Personalization
  alias Lanttern.Schools
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.School
  alias Lanttern.Schools.StaffMember
  alias Lanttern.Schools.Student
  alias Lanttern.StudentsCycleInfo

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
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Options

    * `preload_current_profile` - will preload and prepare user's `current_profile`

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id, opts \\ []) do
    user = Repo.get!(User, id)

    if Keyword.get(opts, :preload_current_profile),
      do: preload_user_current_profile(user),
      else: user
  end

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
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
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

    case Repo.one(query) do
      {%User{} = user, _token_inserted_at} -> preload_user_current_profile(user)
      nil -> nil
    end
  end

  defp preload_user_current_profile(%User{} = user) do
    user = Repo.preload(user, :current_profile)

    profile_settings =
      case user do
        %User{current_profile: %Profile{id: profile_id}} ->
          Personalization.get_profile_settings(profile_id, preloads: :current_school_cycle) ||
            %{}

        _ ->
          %{}
      end

    user
    |> Map.update!(:current_profile, &put_permissions(&1, profile_settings))
    |> Map.update!(:current_profile, &build_flat_profile/1)
    |> Map.update!(:current_profile, &ensure_current_school_cycle(&1, profile_settings))
    |> Map.update!(:current_profile, &put_student_cycle_info_picture(&1))
  end

  defp put_permissions(%Profile{} = profile, profile_settings) do
    permissions = Map.get(profile_settings, :permissions, [])
    Map.put(profile, :permissions, permissions)
  end

  # root admin may not have a current profile
  defp put_permissions(profile, _), do: profile

  defp build_flat_profile(%{type: "staff", staff_member_id: staff_member_id} = profile) do
    {staff_member, school} =
      from(
        sm in StaffMember,
        join: sc in assoc(sm, :school),
        select: {sm, sc}
      )
      |> Repo.get!(staff_member_id)

    profile
    |> Map.put(:name, staff_member.name)
    |> Map.put(:role, staff_member.role)
    |> Map.put(:deactivated_at, staff_member.deactivated_at)
    |> Map.put(:profile_picture_url, staff_member.profile_picture_url)
    |> Map.put(:school_id, school.id)
    |> Map.put(:school_name, school.name)
  end

  defp build_flat_profile(%{type: type} = profile) when type in ["student", "guardian"] do
    student_id =
      case type do
        "student" -> profile.student_id
        "guardian" -> profile.guardian_of_student_id
      end

    {student, school} =
      from(
        st in Student,
        join: sc in assoc(st, :school),
        select: {st, sc}
      )
      |> Repo.get!(student_id)

    profile
    |> Map.put(:name, student.name)
    |> Map.put(:school_id, school.id)
    |> Map.put(:school_name, school.name)
  end

  # root admin may not have a current profile
  defp build_flat_profile(profile), do: profile

  defp ensure_current_school_cycle(
         profile,
         %{current_school_cycle: %Cycle{} = cycle}
       ),
       do: Map.put(profile, :current_school_cycle, cycle)

  defp ensure_current_school_cycle(%{id: profile_id, school_id: school_id} = profile, _)
       when not is_nil(school_id) do
    # when there's no current school cycle in profile at this point
    # try to set the newest school cycle as current
    case Schools.get_newest_parent_cycle_from_school(school_id) do
      nil ->
        profile

      school_cycle ->
        Personalization.set_profile_settings(profile_id, %{
          current_school_cycle_id: school_cycle.id
        })

        Map.put(profile, :current_school_cycle, school_cycle)
    end
  end

  # root admin may not have a current profile
  defp ensure_current_school_cycle(profile, _), do: profile

  defp put_student_cycle_info_picture(%{type: type, current_school_cycle: %Cycle{}} = profile)
       when type in ["student", "guardian"] do
    student_id =
      case type do
        "student" -> profile.student_id
        "guardian" -> profile.guardian_of_student_id
      end

    profile_picture_url =
      StudentsCycleInfo.get_student_cycle_info_by_student_and_cycle(
        student_id,
        profile.current_school_cycle.id
      )
      |> case do
        %{profile_picture_url: profile_picture_url} -> profile_picture_url
        _ -> nil
      end

    Map.put(profile, :profile_picture_url, profile_picture_url)
  end

  defp put_student_cycle_info_picture(profile), do: profile

  @doc """
  Generates a login code for the given user and sends it via email.

  This function deletes any existing login code for the user's email
  before creating a new one to ensure only one valid code exists per email.

  ## Examples

      iex> generate_login_code(user)
      {:ok, %LoginCode{}}
  """
  def generate_login_code(%User{} = user) do
    {plain_code, hashed_code} = LoginCode.generate_code()

    Repo.transact(fn ->
      # Delete any existing login code for this email
      Repo.delete_all(by_email_query(user.email))

      # Create new login code
      login_code = LoginCode.build(user.email, hashed_code)

      with {:ok, login_code} <- Repo.insert(login_code),
           {:ok, _email} <- UserNotifier.deliver_login_code(user, plain_code) do
        {:ok, login_code}
      else
        error -> error
      end
    end)
  end

  @doc """
  Verifies a login code for the given email and returns the associated user.

  If the code is valid and not expired, the login code is deleted immediately
  and the user is returned. If the code is invalid, the attempt count is
  incremented. After @max_attempts failed attempts, the code is invalidated.

  ## Examples

      iex> verify_login_code("user@example.com", "123456")
      {:ok, %User{}}

      iex> verify_login_code("user@example.com", "invalid")
      {:error, :invalid_code}

      iex> verify_login_code("user@example.com", "invalid")  # after @max_attempts
      {:error, :code_invalidated}
  """
  def verify_login_code(email, code) when is_binary(email) and is_binary(code) do
    # First try to find a valid code
    case Repo.one(verify_code_query(email, code)) do
      %LoginCode{} = login_code ->
        verify_and_delete_login_code(login_code, email)

      nil ->
        # Code is invalid, increment attempts or check if already invalidated
        handle_invalid_code_attempt(email, code)
    end
  end

  defp verify_and_delete_login_code(login_code, email) do
    Repo.transact(fn ->
      # Delete the used login code immediately
      Repo.delete!(login_code)

      # Return the user
      case get_user_by_email(email) do
        %User{} = user -> {:ok, user}
        nil -> {:error, :user_not_found}
      end
    end)
  end

  defp handle_invalid_code_attempt(email, _code) do
    attempts_limit = LoginCode.max_attempts() - 1

    # Find any login code for this email to track attempts
    case Repo.one(find_by_email_query(email)) do
      %LoginCode{attempts: attempts} = login_code when attempts >= attempts_limit ->
        # Increment attempts but return code_invalidated (this is the @max_attempts+ attempt)
        login_code
        |> Ecto.Changeset.change(attempts: login_code.attempts + 1)
        |> Repo.update()

        {:error, :code_invalidated}

      %LoginCode{} = login_code ->
        # Increment attempts (this is before @max_attempts)
        login_code
        |> Ecto.Changeset.change(attempts: login_code.attempts + 1)
        |> Repo.update()

        {:error, :invalid_code}

      nil ->
        # No login code found (expired or never existed)
        {:error, :invalid_code}
    end
  end

  @doc """
  Requests a login code for the given email with rate limiting.

  This function checks if a login code request has been made recently
  for the given email using the database. If so, it returns an error.
  Otherwise, it generates and sends a login code if the user exists.

  Returns:
  - `{:ok, :sent}` if the request was processed (regardless of user existence)
  - `{:error, :rate_limited}` if a request was made too recently
  - `{:error, reason}` for other errors during code generation

  ## Examples

      iex> request_login_code("user@example.com")
      {:ok, :sent}

      iex> request_login_code("user@example.com")  # called again within rate limit
      {:error, :rate_limited}

      iex> request_login_code("nonexistent@example.com")
      {:ok, :sent}  # same response for security
  """
  def request_login_code(email) when is_binary(email) do
    case check_rate_limit(email) do
      {:ok, nil} ->
        handle_new_login_request(email)

      {:ok, _rate_limited_until} ->
        {:error, :rate_limited}
    end
  end

  defp check_rate_limit(email) do
    case Repo.one(rate_limited_query(email)) do
      nil -> {:ok, nil}
      %LoginCode{rate_limited_until: rate_limited_until} -> {:ok, rate_limited_until}
    end
  end

  defp handle_new_login_request(email) do
    # Check if user exists and send code
    case get_user_by_email(email) do
      %User{} = user ->
        case generate_login_code(user) do
          {:ok, _login_code} -> {:ok, :sent}
          {:error, reason} -> {:error, reason}
        end

      nil ->
        # For security: same response time and behavior as existing users
        # We still create a rate limiting entry to prevent enumeration
        create_rate_limit_only_entry(email)
        {:ok, :sent}
    end
  end

  defp create_rate_limit_only_entry(email) do
    # Create a dummy entry with placeholder code_hash for rate limiting purposes only
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    rate_limited_until = DateTime.add(now, LoginCode.rate_limit_window_seconds(), :second)

    # Use a placeholder hash that will never match any real code
    placeholder_hash = :crypto.hash(:sha256, "invalid_placeholder_#{System.unique_integer()}")

    %LoginCode{
      email: email,
      code_hash: placeholder_hash,
      attempts: 0,
      rate_limited_until: rate_limited_until
    }
    |> Repo.insert()
  end

  @doc """
  Gets the remaining time in seconds until the rate limit expires for the given email.

  Returns:
  - `{:ok, remaining_seconds}` if rate limit is active
  - `{:ok, nil}` if no rate limit is active for the email

  ## Examples

      iex> get_rate_limit_remaining("user@example.com")
      {:ok, 45}

      iex> get_rate_limit_remaining("user@example.com")  # no active rate limit
      {:ok, nil}
  """
  def get_rate_limit_remaining(email) when is_binary(email) do
    case Repo.one(rate_limited_query(email)) do
      nil ->
        {:ok, nil}

      %LoginCode{rate_limited_until: rate_limited_until} ->
        now = DateTime.utc_now()
        remaining_seconds = DateTime.diff(rate_limited_until, now, :second)
        {:ok, max(remaining_seconds, 0)}
    end
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
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

  @doc """
  Cleans up expired login codes that are also past their rate limit window.

  This function removes login codes that are both expired (older than 5 minutes)
  AND past their rate limit window (older than 60 seconds from rate_limited_until).
  These codes serve no functional purpose and can be safely deleted.

  Returns the number of deleted records.

  ## Examples

      iex> cleanup_expired_login_codes()
      {15, nil}  # 15 records deleted
  """
  def cleanup_expired_login_codes do
    require Logger

    {count, _} = Repo.delete_all(expired_and_past_rate_limit_query())

    if count > 0 do
      Logger.info("LoginCode cleanup: deleted #{count} expired login codes")
    end

    {count, nil}
  end

  @doc """
  Returns the name of the profile
  """
  def get_profile_name(profile) do
    case profile.type do
      "student" -> profile.student.name
      "staff" -> profile.staff_member.name
      "guardian" -> profile.guardian_of_student.name
    end
  end

  @doc """
  Returns the picture URL of the profile
  """
  def get_profile_picture_url(profile) do
    case profile.type do
      "student" -> profile.student.profile_picture_url
      "staff" -> profile.staff_member.profile_picture_url
      "guardian" -> profile.guardian_of_student.profile_picture_url
    end
  end

  ## Token helper

  # passsword disabled in favor of access code login
  # (keep code for future reimplementation)

  # @doc """
  # Gets a user by email and password.

  # ## Examples

  #     iex> get_user_by_email_and_password("foo@example.com", "correct_password")
  #     %User{}

  #     iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
  #     nil

  # """
  # def get_user_by_email_and_password(email, password)
  #     when is_binary(email) and is_binary(password) do
  #   user = Repo.get_by(User, email: email)
  #   if User.valid_password?(user, password), do: user
  # end

  # @doc """
  # Returns an `%Ecto.Changeset{}` for changing the user password.

  # ## Examples

  #     iex> change_user_password(user)
  #     %Ecto.Changeset{data: %User{}}

  # """
  # def change_user_password(user, attrs \\ %{}) do
  #   User.password_changeset(user, attrs, hash_password: false)
  # end

  # @doc """
  # Updates the user password.

  # ## Examples

  #     iex> update_user_password(user, "valid password", %{password: ...})
  #     {:ok, %User{}}

  #     iex> update_user_password(user, "invalid password", %{password: ...})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def update_user_password(user, password, attrs) do
  #   changeset =
  #     user
  #     |> User.password_changeset(attrs)
  #     |> User.validate_current_password(password)

  #   Ecto.Multi.new()
  #   |> Ecto.Multi.update(:user, changeset)
  #   |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
  #   |> Repo.transaction()
  #   |> case do
  #     {:ok, %{user: user}} -> {:ok, user}
  #     {:error, :user, changeset, _} -> {:error, changeset}
  #   end
  # end

  # ## Reset password

  # @doc ~S"""
  # Delivers the reset password email to the given user.

  # ## Examples

  #     iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
  #     {:ok, %{to: ..., body: ...}}

  # """
  # def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
  #     when is_function(reset_password_url_fun, 1) do
  #   {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
  #   Repo.insert!(user_token)
  #   UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  # end

  # @doc """
  # Gets the user by reset password token.

  # ## Examples

  #     iex> get_user_by_reset_password_token("validtoken")
  #     %User{}

  #     iex> get_user_by_reset_password_token("invalidtoken")
  #     nil

  # """
  # def get_user_by_reset_password_token(token) do
  #   with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
  #        %User{} = user <- Repo.one(query) do
  #     user
  #   else
  #     _ -> nil
  #   end
  # end

  # @doc """
  # Resets the user password.

  # ## Examples

  #     iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
  #     {:ok, %User{}}

  #     iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def reset_user_password(user, attrs) do
  #   Ecto.Multi.new()
  #   |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
  #   |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
  #   |> Repo.transaction()
  #   |> case do
  #     {:ok, %{user: user}} -> {:ok, user}
  #     {:error, :user, changeset, _} -> {:error, changeset}
  #   end
  # end

  ## LoginCode queries

  defp verify_code_query(email, code) do
    hashed_code = :crypto.hash(LoginCode.hash_algorithm(), code)
    max_attempts = LoginCode.max_attempts()
    code_validity_minutes = LoginCode.code_validity_in_minutes()

    from lc in LoginCode,
      where: lc.email == ^email,
      where: lc.code_hash == ^hashed_code,
      where: lc.inserted_at > ago(^code_validity_minutes, "minute"),
      where: lc.attempts < ^max_attempts
  end

  defp by_email_query(email) do
    from LoginCode, where: [email: ^email]
  end

  defp rate_limited_query(email) do
    now = DateTime.utc_now()

    from lc in LoginCode,
      where: lc.email == ^email,
      where: lc.rate_limited_until > ^now,
      order_by: [desc: lc.rate_limited_until],
      limit: 1
  end

  defp find_by_email_query(email) do
    from lc in LoginCode,
      where: lc.email == ^email,
      order_by: [desc: lc.inserted_at],
      limit: 1
  end

  defp expired_and_past_rate_limit_query do
    now = DateTime.utc_now()
    code_validity_minutes = LoginCode.code_validity_in_minutes()

    from lc in LoginCode,
      where: lc.inserted_at <= ago(^code_validity_minutes, "minute"),
      where: lc.rate_limited_until <= ^now
  end
end
