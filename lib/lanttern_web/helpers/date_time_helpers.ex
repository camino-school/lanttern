defmodule LantternWeb.DateTimeHelpers do
  @moduledoc """
  Helper functions related to date and time
  """

  use Gettext, backend: Lanttern.Gettext

  @default_formats_map %{
    "en" => "MMM d, y, HH:mm",
    "pt_BR" => "d MMM y, HH:mm"
  }

  @default_format @default_formats_map["en"]

  defp maybe_convert_naive(%NaiveDateTime{} = datetime),
    do: datetime |> Timex.to_datetime()

  defp maybe_convert_naive(datetime), do: datetime

  @spec days_and_hours_between(
          datetime_1 :: DateTime.t() | NaiveDateTime.t(),
          datetime_2 :: DateTime.t() | NaiveDateTime.t(),
          format :: binary()
        ) :: String.t()
  def days_and_hours_between(datetime_1, datetime_2, format \\ "short") do
    datetime_1 =
      case datetime_1 do
        %NaiveDateTime{} -> DateTime.from_naive!(datetime_1, "Etc/UTC")
        _ -> datetime_1
      end

    datetime_2 =
      case datetime_2 do
        %NaiveDateTime{} -> DateTime.from_naive!(datetime_2, "Etc/UTC")
        _ -> datetime_2
      end

    days = DateTime.diff(datetime_2, datetime_1, :day)
    hours = DateTime.diff(datetime_2, datetime_1, :hour) - days * 24

    render_days_and_hours(days, hours, format)
  end

  defp render_days_and_hours(1, 1, "long"), do: gettext("1 day and 1 hour")
  defp render_days_and_hours(0, 0, "long"), do: gettext("some minutes")
  defp render_days_and_hours(1, h, "long"), do: gettext("1 day and %{h} hours", h: h)
  defp render_days_and_hours(0, h, "long"), do: gettext("%{h} hours", h: h)
  defp render_days_and_hours(d, 1, "long"), do: gettext("%{d} days and 1 hour", d: d)
  defp render_days_and_hours(d, 0, "long"), do: gettext("%{d} days", d: d)
  defp render_days_and_hours(d, h, "long"), do: gettext("%{d} days and %{h} hours", d: d, h: h)
  defp render_days_and_hours(d, h, _), do: "#{d}d #{h}h"

  def format_simple_time(time) do
    {:ok, time} =
      time
      |> Lanttern.Cldr.DateTime.to_string(format: "hh:mm")

    time
  end

  @doc """
  Wrapper around `Timex.to_datetime/2` and Cldr formatter which renders the formated time
  using a datetime, browser timezone, and a optional format map.
  The format map is a map of locale to format string e.g:

   ## format of acceptable map format language and format string

    %{
      "en" => "MMM d, y",
      "pt_BR" => "d MMM y"
    }


  If the locale is not found in the map,
  the default format is used. The default format is "MMM d, y, HH:mm".
  """
  def format_by_locale(datetime, tz, format_map \\ %{}) do
    locale = Gettext.get_locale(Lanttern.Gettext)
    format = Map.get(format_map, locale, get_default_format(locale))

    {:ok, format} =
      datetime
      |> maybe_convert_naive()
      |> Timex.to_datetime(tz || Application.get_env(:lanttern, :default_timezone))
      |> Lanttern.Cldr.DateTime.to_string(format: format, locale: locale)

    format
  end

  def get_default_format(locale),
    do: Map.get(@default_formats_map, locale, @default_format)
end
