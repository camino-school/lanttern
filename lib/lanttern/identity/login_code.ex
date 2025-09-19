defmodule Lanttern.Identity.LoginCode do
  @moduledoc """
  The LoginCode schema for passwordless authentication using 6-digit codes.
  """

  use Ecto.Schema
  import Ecto.Query
  alias Lanttern.Identity.LoginCode

  @hash_algorithm :sha256
  @code_validity_in_minutes 5

  schema "login_codes" do
    field :email, :string
    field :code_hash, :binary

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
  """
  def build(email, hashed_code) do
    %LoginCode{
      email: email,
      code_hash: hashed_code
    }
  end

  @doc """
  Returns a query to find a login code by email and plain code.
  The query also validates that the code hasn't expired.
  """
  def verify_code_query(email, code) do
    hashed_code = :crypto.hash(@hash_algorithm, code)

    from lc in LoginCode,
      where: lc.email == ^email,
      where: lc.code_hash == ^hashed_code,
      where: lc.inserted_at > ago(^@code_validity_in_minutes, "minute")
  end

  @doc """
  Returns a query to find login codes by email (for cleanup purposes).
  """
  def by_email_query(email) do
    from LoginCode, where: [email: ^email]
  end
end
