defmodule Lanttern.Grading.ConversionRule do
  use Ecto.Schema
  import Ecto.Changeset
  import PolymorphicEmbed

  schema "conversion_rules" do
    field :name, :string

    belongs_to :from_scale, Lanttern.Grading.Scale
    belongs_to :to_scale, Lanttern.Grading.Scale

    polymorphic_embeds_many(:conversions,
      types: [
        o_to_n: Lanttern.Grading.OrdinalToNumericConversion,
        n_to_o: Lanttern.Grading.NumericToOrdinalConversion,
        o_to_o: Lanttern.Grading.OrdinalToOrdinalConversion
      ],
      on_type_not_found: :raise,
      on_replace: :delete
    )

    timestamps()
  end

  @doc false
  def changeset(conversion_rule, attrs) do
    conversion_rule
    |> cast(attrs, [:name, :from_scale_id, :to_scale_id])
    |> validate_required([:name, :from_scale_id, :to_scale_id])
    |> unique_constraint([:from_scale_id, :to_scale_id], message: "conversion already exists")
    |> check_constraint(:from_scale_id,
      name: :from_and_to_scales_should_be_different,
      message: "from and to scales should be different"
    )
    |> maybe_cast_polymorphic_embed(attrs)
  end

  defp maybe_cast_polymorphic_embed(changeset, %{conversions: conversions} = _attrs)
       when is_list(conversions) do
    cast_polymorphic_embed(changeset, :conversions)
  end

  defp maybe_cast_polymorphic_embed(changeset, _attrs), do: changeset
end

defmodule Lanttern.Grading.OrdinalToNumericConversion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :to_value, :float
    belongs_to :from_ordinal, Lanttern.Grading.OrdinalValue
  end

  def changeset(ordinal_to_numeric_conversion, attrs) do
    ordinal_to_numeric_conversion
    |> cast(attrs, [:from_ordinal_id, :to_value])
    |> validate_required([:from_ordinal_id, :to_value])
  end
end

defmodule Lanttern.Grading.NumericToOrdinalConversion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :breakpoints, {:array, :float}
    field :ordinal_values_ids, {:array, :id}
  end

  def changeset(ordinal_to_ordinal_conversion, attrs) do
    ordinal_to_ordinal_conversion
    |> cast(attrs, [:breakpoints, :ordinal_values_ids])
    |> validate_required([:breakpoints, :ordinal_values_ids])
  end
end

defmodule Lanttern.Grading.OrdinalToOrdinalConversion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    belongs_to :from_ordinal, Lanttern.Grading.OrdinalValue
    belongs_to :to_ordinal, Lanttern.Grading.OrdinalValue
  end

  def changeset(ordinal_to_ordinal_conversion, attrs) do
    ordinal_to_ordinal_conversion
    |> cast(attrs, [:from_ordinal_id, :to_ordinal_id])
    |> validate_required([:from_ordinal_id, :to_ordinal_id])
  end
end
