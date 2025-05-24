defmodule Lanttern.UserFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def user_factory do
        %Lanttern.Identity.User{
          email: "email@mailer",
          hashed_password: "hashed_password"
        }
      end
    end
  end
end
