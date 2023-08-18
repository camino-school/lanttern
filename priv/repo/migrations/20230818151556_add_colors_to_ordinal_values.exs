defmodule Lanttern.Repo.Migrations.AddColorsToOrdinalValues do
  use Ecto.Migration

  def change do
    alter table(:ordinal_values) do
      add :bg_color, :string
      add :text_color, :string
    end

    create constraint(
             :ordinal_values,
             :ordinal_value_bg_color_should_be_hex,
             check: "bg_color ~* '^#[a-f0-9]{6}$'"
           )

    create constraint(
             :ordinal_values,
             :ordinal_value_text_color_should_be_hex,
             check: "text_color ~* '^#[a-f0-9]{6}$'"
           )
  end
end
