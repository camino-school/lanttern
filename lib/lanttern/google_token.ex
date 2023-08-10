defmodule Lanttern.GoogleToken do
  use Joken.Config

  @client_id Application.compile_env(:lanttern, LantternWeb.UserAuth)
             |> Keyword.get(:google_client_id)
  @google_iss_1 "https://accounts.google.com"
  @google_iss_2 "accounts.google.com"

  add_hook(JokenJwks, strategy: Lanttern.GoogleTokenStrategy)

  def token_config do
    %{}
    |> add_claim("aud", fn -> @client_id end, &(&1 == @client_id))
    |> add_claim("iss", fn -> @google_iss_1 end, &(&1 == @google_iss_1 or &1 == @google_iss_2))
    |> add_claim("exp", fn -> generate_exp() end, &(&1 > Timex.now() |> Timex.to_unix()))
  end

  defp generate_exp() do
    Timex.now()
    |> Timex.add(Timex.Duration.from_days(30))
  end
end

# I know this is not the best practice,
# but I think it's ok to create a new module in the same file for this specific use case
defmodule Lanttern.GoogleTokenStrategy do
  use JokenJwks.DefaultStrategyTemplate

  def init_opts(opts) do
    url = "https://www.googleapis.com/oauth2/v3/certs"
    Keyword.merge(opts, jwks_url: url)
  end
end
