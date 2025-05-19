defmodule Lanttern.SchoolFactory do
  defmacro __using__(_opts) do
    quote do
      def school_factory do
        %Lanttern.Schools.School{
          name: "",
          logo_image_url: "",
          bg_color: "",
          text_color: "",
        }
      end
    end
  end
end
