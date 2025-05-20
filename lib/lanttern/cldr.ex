defmodule Lanttern.Cldr do
  use Cldr,
    default_locale: "en",
    locales: ["en", "pt"],
    otp_app: :lanttern,
    default_locale: "en",
    gettext: Lanttern.Gettext,
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end
