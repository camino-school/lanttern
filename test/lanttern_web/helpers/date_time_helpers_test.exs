defmodule LantternWeb.DateTimeHelpersTest do
  use ExUnit.Case

  import LantternWeb.DateTimeHelpers

  setup do
    # Store original locale and reset after each test
    original_locale = Gettext.get_locale(Lanttern.Gettext)

    on_exit(fn ->
      Gettext.put_locale(Lanttern.Gettext, original_locale)
    end)

    :ok
  end

  describe "calculate_age/2" do
    test "returns nil when birthdate is nil" do
      today = ~D[2026-02-12]
      assert calculate_age(nil, today) == nil
    end

    test "returns nil when birthdate is in the future" do
      today = ~D[2026-02-12]
      future_date = ~D[2026-02-13]
      assert calculate_age(future_date, today) == nil
    end

    test "calculates exact age with matching day of month" do
      today = ~D[2026-02-12]
      birthdate = ~D[2001-02-12]
      assert calculate_age(birthdate, today) == {25, 0}
    end

    test "calculates age correctly when birthday hasn't occurred this month" do
      today = ~D[2026-02-12]
      birthdate = ~D[1996-02-15]

      assert calculate_age(birthdate, today) == {29, 11}
    end

    test "calculates age correctly when birthday hasn't occurred this year" do
      today = ~D[2026-02-12]
      birthdate = ~D[2006-01-12]

      assert calculate_age(birthdate, today) == {20, 1}
    end

    test "handles leap year birthdate on a non-leap year" do
      today = ~D[2026-03-01]
      birthdate = ~D[2004-02-29]

      assert calculate_age(birthdate, today) == {22, 0}
    end

    test "calculates age when birthday is today" do
      today = ~D[2026-02-12]
      birthdate = ~D[2008-02-12]
      assert calculate_age(birthdate, today) == {18, 0}
    end

    test "calculates age with months when birthday hasn't passed this month" do
      today = ~D[2026-02-12]
      birthdate = ~D[2021-02-15]

      assert calculate_age(birthdate, today) == {4, 11}
    end

    test "handles last day of month edge case" do
      today = ~D[2026-01-31]
      birthdate = ~D[2000-01-15]

      assert calculate_age(birthdate, today) == {26, 0}
    end

    test "handles end of year calculation" do
      today = ~D[2026-12-31]
      birthdate = ~D[2000-12-31]

      assert calculate_age(birthdate, today) == {26, 0}
    end

    test "uses default today when not provided" do
      # This test uses the default Date.utc_today()
      birthdate = Date.add(Date.utc_today(), -365 * 5)
      {years, _months} = calculate_age(birthdate)

      assert years >= 4 and years <= 5
    end
  end

  describe "format_age_short/1" do
    test "returns empty string when age is nil" do
      assert format_age_short(nil) == ""
    end

    test "formats age with years and months in English" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      result = format_age_short({2, 9})
      assert result == "2y 9m"
    end

    test "formats age with years and months in Portuguese" do
      Gettext.put_locale(Lanttern.Gettext, "pt_BR")
      result = format_age_short({2, 9})
      assert result == "2a 9m"
    end

    test "formats age with zero months" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      result = format_age_short({5, 0})
      assert result == "5y 0m"
    end

    test "formats age with zero years" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      result = format_age_short({0, 6})
      assert result == "0y 6m"
    end
  end

  describe "format_age_full/1" do
    test "returns empty string when age is nil" do
      assert format_age_full(nil) == ""
    end

    test "formats age with multiple years and months in English" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      result = format_age_full({2, 9})
      assert result == "2 years, 9 months"
    end

    test "formats singular year in English" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      result = format_age_full({1, 3})
      assert result == "1 year, 3 months"
    end

    test "formats singular month in English" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      result = format_age_full({2, 1})
      assert result == "2 years, 1 month"
    end

    test "formats both singular in English" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      result = format_age_full({1, 1})
      assert result == "1 year, 1 month"
    end

    test "formats age with multiple years and months in Portuguese" do
      Gettext.put_locale(Lanttern.Gettext, "pt_BR")
      result = format_age_full({2, 9})
      assert result == "2 anos, 9 meses"
    end

    test "formats singular year in Portuguese" do
      Gettext.put_locale(Lanttern.Gettext, "pt_BR")
      result = format_age_full({1, 3})
      assert result == "1 ano, 3 meses"
    end

    test "formats zero years and months" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      result = format_age_full({0, 0})
      assert result == "0 years, 0 months"
    end
  end

  describe "format_birthdate/1" do
    test "returns empty string when birthdate is nil" do
      assert format_birthdate(nil) == ""
    end

    test "formats birthdate in English format (MM/dd/yyyy)" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      birthdate = Date.new!(1988, 2, 20)
      result = format_birthdate(birthdate)
      assert result == "02/20/1988"
    end

    test "formats birthdate in Portuguese format (dd/MM/yyyy)" do
      Gettext.put_locale(Lanttern.Gettext, "pt_BR")
      birthdate = Date.new!(1988, 2, 20)
      result = format_birthdate(birthdate)
      assert result == "20/02/1988"
    end

    test "formats birthdate with different day and month" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      birthdate = Date.new!(2000, 12, 25)
      result = format_birthdate(birthdate)
      assert result == "12/25/2000"
    end

    test "formats leap year date" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      birthdate = Date.new!(2000, 2, 29)
      result = format_birthdate(birthdate)
      assert result == "02/29/2000"
    end
  end

  describe "format_simple_time/1" do
    test "formats time correctly" do
      time = ~T[14:30:00]
      result = format_simple_time(time)
      assert result == "14:30"
    end

    test "formats midnight" do
      time = ~T[00:00:00]
      result = format_simple_time(time)
      assert result == "00:00"
    end

    test "formats time with leading zeros" do
      time = ~T[09:05:30]
      result = format_simple_time(time)
      assert result == "09:05"
    end
  end

  describe "days_and_hours_between/3" do
    test "calculates days and hours between two datetimes" do
      datetime_1 = DateTime.new!(Date.utc_today(), ~T[00:00:00], "Etc/UTC")
      datetime_2 = DateTime.add(datetime_1, 1 * 24 * 3600 + 5 * 3600)

      result = days_and_hours_between(datetime_1, datetime_2, "short")
      assert result == "1d 5h"
    end

    test "calculates zero days and hours" do
      datetime = DateTime.new!(Date.utc_today(), ~T[12:00:00], "Etc/UTC")
      result = days_and_hours_between(datetime, datetime, "short")
      assert result == "0d 0h"
    end

    test "formats with long format for 1 day and 1 hour in English" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      datetime_1 = DateTime.new!(Date.utc_today(), ~T[00:00:00], "Etc/UTC")
      datetime_2 = DateTime.add(datetime_1, 1 * 24 * 3600 + 1 * 3600)

      result = days_and_hours_between(datetime_1, datetime_2, "long")
      assert result == "1 day and 1 hour"
    end

    test "formats with long format for multiple days and hours in English" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      datetime_1 = DateTime.new!(Date.utc_today(), ~T[00:00:00], "Etc/UTC")
      datetime_2 = DateTime.add(datetime_1, 5 * 24 * 3600 + 3 * 3600)

      result = days_and_hours_between(datetime_1, datetime_2, "long")
      assert result == "5 days and 3 hours"
    end

    test "handles naive datetimes" do
      naive_dt_1 = NaiveDateTime.new!(Date.utc_today(), ~T[00:00:00])
      naive_dt_2 = NaiveDateTime.add(naive_dt_1, 1 * 24 * 3600 + 2 * 3600)

      result = days_and_hours_between(naive_dt_1, naive_dt_2, "short")
      assert result == "1d 2h"
    end

    test "defaults to short format when not specified" do
      datetime_1 = DateTime.new!(Date.utc_today(), ~T[00:00:00], "Etc/UTC")
      datetime_2 = DateTime.add(datetime_1, 2 * 24 * 3600 + 4 * 3600)

      result = days_and_hours_between(datetime_1, datetime_2)
      assert result == "2d 4h"
    end

    test "formats 0 hours in long format in English" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      datetime_1 = DateTime.new!(Date.utc_today(), ~T[00:00:00], "Etc/UTC")
      datetime_2 = DateTime.add(datetime_1, 3 * 24 * 3600)

      result = days_and_hours_between(datetime_1, datetime_2, "long")
      assert result == "3 days"
    end

    test "formats 0 days and 0 hours in long format in English" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      datetime = DateTime.new!(Date.utc_today(), ~T[12:00:00], "Etc/UTC")

      result = days_and_hours_between(datetime, datetime, "long")
      assert result == "some minutes"
    end
  end

  describe "format_by_locale/3" do
    test "formats datetime using locale from Gettext" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      dt = DateTime.new!(Date.new!(2024, 3, 15), ~T[14:30:00], "Etc/UTC")
      result = format_by_locale(dt, "Etc/UTC")
      assert String.contains?(result, "Mar")
      assert String.contains?(result, "15")
    end

    test "uses custom format map when provided" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      dt = DateTime.new!(Date.new!(2024, 3, 15), ~T[14:30:00], "Etc/UTC")
      custom_format = %{"en" => "yyyy-MM-dd"}
      result = format_by_locale(dt, "Etc/UTC", custom_format)
      assert result == "2024-03-15"
    end

    test "handles naive datetime conversion" do
      Gettext.put_locale(Lanttern.Gettext, "en")
      naive_dt = NaiveDateTime.new!(Date.new!(2024, 3, 15), ~T[14:30:00])
      result = format_by_locale(naive_dt, "Etc/UTC")
      assert is_binary(result)
      assert String.length(result) > 0
    end
  end

  describe "get_default_format/1" do
    test "returns English format for en locale" do
      result = get_default_format("en")
      assert result == "MMM d, y, HH:mm"
    end

    test "returns Portuguese format for pt_BR locale" do
      result = get_default_format("pt_BR")
      assert result == "d MMM y, HH:mm"
    end

    test "returns English format as fallback for unknown locale" do
      result = get_default_format("unknown")
      assert result == "MMM d, y, HH:mm"
    end
  end
end
