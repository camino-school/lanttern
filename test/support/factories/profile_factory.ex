defmodule Lanttern.ProfileFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def profile_factory do
        %Lanttern.Identity.Profile{
          type: "staff",
          user: build(:user),
          staff_member: build(:staff_member),
        }
      end
    end
  end
end
