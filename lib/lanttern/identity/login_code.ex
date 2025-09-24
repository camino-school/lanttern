defmodule Lanttern.Identity.LoginCode do
  @moduledoc """
  The LoginCode schema for passwordless authentication using 6-digit codes.
  """

  use Ecto.Schema

  @hash_algorithm :sha256
  @code_validity_in_minutes 5
  @max_attempts 3
  @rate_limit_window_seconds 60

  schema "login_codes" do
    field :email, :string
    field :code_hash, :binary
    field :attempts, :integer, default: 0
    field :rate_limited_until, :utc_datetime

    timestamps(updated_at: false)
  end

  @doc """
  Generates a 6-digit numeric code and returns both the plain code and its hashed version.
  """
  def generate_code do
    # Generate a 6-digit code (100000-999999)
    code =
      :crypto.strong_rand_bytes(4)
      |> :binary.decode_unsigned()
      |> rem(900_000)
      |> Kernel.+(100_000)
      |> Integer.to_string()

    hashed_code = :crypto.hash(@hash_algorithm, code)

    {code, hashed_code}
  end

  @doc """
  Creates a new LoginCode struct with the given email and hashed code.
  Sets rate limiting window and initializes attempts to 0.
  """
  def build(email, hashed_code) do
    now = DateTime.utc_now(:second)
    rate_limited_until = DateTime.add(now, @rate_limit_window_seconds, :second)

    %__MODULE__{
      email: email,
      code_hash: hashed_code,
      attempts: 0,
      rate_limited_until: rate_limited_until
    }
  end

  @doc """
  Returns the maximum number of attempts allowed.
  """
  def max_attempts, do: @max_attempts

  @doc """
  Returns the rate limit window in seconds.
  """
  def rate_limit_window_seconds, do: @rate_limit_window_seconds

  @doc """
  Returns the code validity in minutes.
  """
  def code_validity_in_minutes, do: @code_validity_in_minutes

  @doc """
  Returns the hash algorithm used for codes.
  """
  def hash_algorithm, do: @hash_algorithm
end
