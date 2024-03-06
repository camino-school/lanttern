defmodule Lanttern.Repo.Migrations.AddYearToReportCards do
  use Ecto.Migration

  def change do
    alter table(:report_cards) do
      add :year_id, references(:years, on_delete: :nothing)
    end

    create index(:report_cards, [:year_id])

    # link existing report cards to an existing year,
    # enabling to set the field as not null
    execute "UPDATE report_cards SET year_id = years.id FROM years", ""

    # add not null constraints to report_cards' year_id
    execute "ALTER TABLE report_cards ALTER COLUMN year_id SET NOT NULL", ""
  end
end
