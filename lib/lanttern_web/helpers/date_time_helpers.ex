defmodule LantternWeb.DateTimeHelpers do
  @moduledoc """
  Helper functions related to date and time
  """

  @doc """
  Wrapper around `Timex.format!/3` which renders the formated time
  using the local timezone
  """
  def format_local!(datetime, format_string) do
    datetime
    |> maybe_convert_naive()
    |> Timex.local()
    |> Timex.format!(format_string)
  end

  defp maybe_convert_naive(%NaiveDateTime{} = datetime),
    do: datetime |> Timex.to_datetime()

  defp maybe_convert_naive(datetime), do: datetime
end
