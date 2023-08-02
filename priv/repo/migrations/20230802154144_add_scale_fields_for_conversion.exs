defmodule Lanttern.Repo.Migrations.AddScaleFieldsForConversion do
  use Ecto.Migration

  def change do
    alter table(:ordinal_values) do
      add :normalized_value, :float, null: false, default: 0.0
      remove :order, :integer, null: false, default: 0
    end

    create constraint(
             :ordinal_values,
             :normalized_value_should_be_between_0_and_1,
             check: "normalized_value >= 0 and normalized_value <= 1"
           )

    alter table(:grading_scales) do
      add :breakpoints, {:array, :float}
    end

    create constraint(
             :grading_scales,
             :breakpoints_should_be_between_0_and_1,
             check: "0 < all(breakpoints) and 1 > all(breakpoints)"
           )
  end
end
