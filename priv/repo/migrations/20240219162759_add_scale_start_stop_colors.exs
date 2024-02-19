defmodule Lanttern.Repo.Migrations.AddScaleStartStopColors do
  use Ecto.Migration

  def change do
    alter table(:grading_scales) do
      add :start_bg_color, :string
      add :start_text_color, :string
      add :stop_bg_color, :string
      add :stop_text_color, :string
    end

    create constraint(
             :grading_scales,
             :scale_start_bg_color_should_be_hex,
             check: "start_bg_color ~* '^#[a-f0-9]{6}$'"
           )

    create constraint(
             :grading_scales,
             :scale_start_text_color_should_be_hex,
             check: "start_text_color ~* '^#[a-f0-9]{6}$'"
           )

    create constraint(
             :grading_scales,
             :scale_stop_bg_color_should_be_hex,
             check: "stop_bg_color ~* '^#[a-f0-9]{6}$'"
           )

    create constraint(
             :grading_scales,
             :scale_stop_text_color_should_be_hex,
             check: "stop_text_color ~* '^#[a-f0-9]{6}$'"
           )
  end
end
