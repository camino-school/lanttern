defmodule LantternWeb.ConversionRuleController do
  use LantternWeb, :controller

  alias Lanttern.Grading
  alias Lanttern.Grading.ConversionRule

  def index(conn, _params) do
    conversion_rules = Grading.list_conversion_rules([:from_scale, :to_scale])
    render(conn, :index, conversion_rules: conversion_rules)
  end

  def new(conn, _params) do
    options = generate_scale_options()
    changeset = Grading.change_conversion_rule(%ConversionRule{})
    render(conn, :new, scale_options: options, changeset: changeset)
  end

  def create(conn, %{"conversion_rule" => conversion_rule_params}) do
    case Grading.create_conversion_rule(conversion_rule_params) do
      {:ok, conversion_rule} ->
        conn
        |> put_flash(:info, "Conversion rule created successfully.")
        |> redirect(to: ~p"/grading/conversion_rules/#{conversion_rule}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_scale_options()
        render(conn, :new, scale_options: options, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    conversion_rule = Grading.get_conversion_rule!(id, [:from_scale, :to_scale])
    render(conn, :show, conversion_rule: conversion_rule)
  end

  def edit(conn, %{"id" => id}) do
    conversion_rule = Grading.get_conversion_rule!(id)
    options = generate_scale_options()
    changeset = Grading.change_conversion_rule(conversion_rule)

    render(conn, :edit,
      conversion_rule: conversion_rule,
      scale_options: options,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "conversion_rule" => conversion_rule_params}) do
    conversion_rule = Grading.get_conversion_rule!(id)

    case Grading.update_conversion_rule(conversion_rule, conversion_rule_params) do
      {:ok, conversion_rule} ->
        conn
        |> put_flash(:info, "Conversion rule updated successfully.")
        |> redirect(to: ~p"/grading/conversion_rules/#{conversion_rule}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_scale_options()

        render(conn, :edit,
          conversion_rule: conversion_rule,
          scale_options: options,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    conversion_rule = Grading.get_conversion_rule!(id)
    {:ok, _conversion_rule} = Grading.delete_conversion_rule(conversion_rule)

    conn
    |> put_flash(:info, "Conversion rule deleted successfully.")
    |> redirect(to: ~p"/grading/conversion_rules")
  end

  defp generate_scale_options() do
    Grading.list_scales()
    |> Enum.map(fn s -> ["#{s.name}": s.id] end)
    |> Enum.concat()
  end
end
