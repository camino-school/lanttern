defmodule Lanttern.SchoolFactory do
  @moduledoc """
  Factory for the School schema.
  This factory is used to create instances of the School schema for testing purposes.
  It provides a default set of attributes for the School schema, which can be overridden
  when creating a new instance.
  """
  defmacro __using__(_opts) do
    quote do
      def school_factory do
        %Lanttern.Schools.School{
          name: "",
          logo_image_url: "",
          bg_color: "#111111",
          text_color: "#ffffff",
        }
      end
    end
  end
end
