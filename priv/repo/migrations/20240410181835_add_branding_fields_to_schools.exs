defmodule Lanttern.Repo.Migrations.AddBrandingFieldsToSchools do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add :logo_image_url, :text
      add :bg_color, :string
      add :text_color, :string
    end

    create constraint(
             :schools,
             :school_bg_color_should_be_hex,
             check: "bg_color ~* '^#[a-f0-9]{6}$'"
           )

    create constraint(
             :schools,
             :school_text_color_should_be_hex,
             check: "text_color ~* '^#[a-f0-9]{6}$'"
           )
  end
end
