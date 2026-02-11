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
      |> Lanttern.Cldr.DateTime.to_string(format: "HH:mm")

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

  @doc """
  Calculates age in years and months from a birthdate.

  Returns a tuple {years, months} or nil if birthdate is nil.
  """
  @spec calculate_age(Date.t() | nil) :: {non_neg_integer(), non_neg_integer()} | nil
  def calculate_age(nil), do: nil

  def calculate_age(%Date{} = birthdate) do
    today = Date.utc_today()

    # Return nil if birthdate is in the future
    case Date.compare(birthdate, today) do
      :gt -> nil
      _ -> do_calculate_age(birthdate, today)
    end
  end

  defp do_calculate_age(%Date{} = birthdate, %Date{} = today) do
    years = today.year - birthdate.year
    months = today.month - birthdate.month

    {years, months} = adjust_for_year_boundary(years, months)
    adjust_for_day_of_month(years, months, today.day, birthdate.day)
  end

  defp adjust_for_year_boundary(years, months) when months < 0 do
    {years - 1, months + 12}
  end

  defp adjust_for_year_boundary(years, months) do
    {years, months}
  end

  defp adjust_for_day_of_month(years, months, today_day, birthdate_day)
       when today_day < birthdate_day and months == 0 do
    {years - 1, 11}
  end

  defp adjust_for_day_of_month(years, months, today_day, birthdate_day)
       when today_day < birthdate_day do
    {years, months - 1}
  end

  defp adjust_for_day_of_month(years, months, _today_day, _birthdate_day) do
    {years, months}
  end

  @doc """
  Formats age as abbreviated years and months (e.g., "2y 9m" for en, "2a 9m" for pt_BR).

  Returns empty string if age is nil.
  """
  @spec format_age_short({non_neg_integer(), non_neg_integer()} | nil) :: String.t()
  def format_age_short(nil), do: ""

  def format_age_short({years, months}) do
    years_abbr = gettext("y")
    months_abbr = gettext("m")
    "#{years}#{years_abbr} #{months}#{months_abbr}"
  end

  @doc """
  Formats age as full years and months (e.g., "2 years, 9 months").

  Returns empty string if age is nil.
  """
  @spec format_age_full({non_neg_integer(), non_neg_integer()} | nil) :: String.t()
  def format_age_full(nil), do: ""

  def format_age_full({years, months}) do
    years_text = ngettext("%{count} year", "%{count} years", years, count: years)
    months_text = ngettext("%{count} month", "%{count} months", months, count: months)

    "#{years_text}, #{months_text}"
  end

  @doc """
  Formats birthdate as a localized date string (e.g., "02/20/1988" or "20/02/1988").

  Returns empty string if birthdate is nil.
  """
  @spec format_birthdate(Date.t() | nil) :: String.t()
  def format_birthdate(nil), do: ""

  def format_birthdate(%Date{} = birthdate) do
    locale = Gettext.get_locale(Lanttern.Gettext)

    format_map = %{
      "en" => "MM/dd/yyyy",
      "pt_BR" => "dd/MM/yyyy"
    }

    format = Map.get(format_map, locale, format_map["en"])

    {:ok, formatted} = Lanttern.Cldr.Date.to_string(birthdate, format: format, locale: locale)

    formatted
  end
end
