defmodule Lanttern.Cldr do
  @moduledoc """
  This module provides the CLDR configuration
  for the Lanttern application. It sets up the default locale, available locales,
  and the providers for date/time formatting.
  """
  use Cldr,
    otp_app: :lanttern,
    default_locale: "en",
    locales: ["en", "pt"],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end
