defmodule LantternWeb.ConversionRuleControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.GradingFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil, conversions: nil}

  describe "index" do
    test "lists all conversion_rules", %{conn: conn} do
      conn = get(conn, ~p"/grading/conversion_rules")
      assert html_response(conn, 200) =~ "Listing Conversion rules"
    end
  end

  describe "new conversion_rule" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/grading/conversion_rules/new")
      assert html_response(conn, 200) =~ "New Conversion rule"
    end
  end

  describe "create conversion_rule" do
    test "redirects to show when data is valid", %{conn: conn} do
      from_scale = scale_fixture()
      to_scale = scale_fixture()

      create_attrs =
        @create_attrs
        |> Map.put_new(:from_scale_id, from_scale.id)
        |> Map.put_new(:to_scale_id, to_scale.id)

      conn = post(conn, ~p"/grading/conversion_rules", conversion_rule: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/grading/conversion_rules/#{id}"

      conn = get(conn, ~p"/grading/conversion_rules/#{id}")
      assert html_response(conn, 200) =~ "Conversion rule #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/grading/conversion_rules", conversion_rule: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Conversion rule"
    end
  end

  describe "edit conversion_rule" do
    setup [:create_conversion_rule]

    test "renders form for editing chosen conversion_rule", %{
      conn: conn,
      conversion_rule: conversion_rule
    } do
      conn = get(conn, ~p"/grading/conversion_rules/#{conversion_rule}/edit")
      assert html_response(conn, 200) =~ "Edit Conversion rule"
    end
  end

  describe "update conversion_rule" do
    setup [:create_conversion_rule]

    test "redirects when data is valid", %{conn: conn, conversion_rule: conversion_rule} do
      conn =
        put(conn, ~p"/grading/conversion_rules/#{conversion_rule}",
          conversion_rule: @update_attrs
        )

      assert redirected_to(conn) == ~p"/grading/conversion_rules/#{conversion_rule}"

      conn = get(conn, ~p"/grading/conversion_rules/#{conversion_rule}")
      assert inspect(html_response(conn, 200) =~ "some updated name")
    end

    test "renders errors when data is invalid", %{conn: conn, conversion_rule: conversion_rule} do
      conn =
        put(conn, ~p"/grading/conversion_rules/#{conversion_rule}",
          conversion_rule: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Conversion rule"
    end
  end

  describe "delete conversion_rule" do
    setup [:create_conversion_rule]

    test "deletes chosen conversion_rule", %{conn: conn, conversion_rule: conversion_rule} do
      conn = delete(conn, ~p"/grading/conversion_rules/#{conversion_rule}")
      assert redirected_to(conn) == ~p"/grading/conversion_rules"

      assert_error_sent 404, fn ->
        get(conn, ~p"/grading/conversion_rules/#{conversion_rule}")
      end
    end
  end

  defp create_conversion_rule(_) do
    conversion_rule = conversion_rule_fixture()
    %{conversion_rule: conversion_rule}
  end
end
