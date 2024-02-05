defmodule Lanttern.ReportingTest do
  use Lanttern.DataCase

  alias Lanttern.Reporting

  describe "report_cards" do
    alias Lanttern.Reporting.ReportCard

    import Lanttern.ReportingFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_report_cards/0 returns all report_cards" do
      report_card = report_card_fixture()
      assert Reporting.list_report_cards() == [report_card]
    end

    test "get_report_card!/1 returns the report_card with given id" do
      report_card = report_card_fixture()
      assert Reporting.get_report_card!(report_card.id) == report_card
    end

    test "create_report_card/1 with valid data creates a report_card" do
      school_cycle = Lanttern.SchoolsFixtures.cycle_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        school_cycle_id: school_cycle.id
      }

      assert {:ok, %ReportCard{} = report_card} = Reporting.create_report_card(valid_attrs)
      assert report_card.name == "some name"
      assert report_card.description == "some description"
    end

    test "create_report_card/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Reporting.create_report_card(@invalid_attrs)
    end

    test "update_report_card/2 with valid data updates the report_card" do
      report_card = report_card_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %ReportCard{} = report_card} =
               Reporting.update_report_card(report_card, update_attrs)

      assert report_card.name == "some updated name"
      assert report_card.description == "some updated description"
    end

    test "update_report_card/2 with invalid data returns error changeset" do
      report_card = report_card_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Reporting.update_report_card(report_card, @invalid_attrs)

      assert report_card == Reporting.get_report_card!(report_card.id)
    end

    test "delete_report_card/1 deletes the report_card" do
      report_card = report_card_fixture()
      assert {:ok, %ReportCard{}} = Reporting.delete_report_card(report_card)
      assert_raise Ecto.NoResultsError, fn -> Reporting.get_report_card!(report_card.id) end
    end

    test "change_report_card/1 returns a report_card changeset" do
      report_card = report_card_fixture()
      assert %Ecto.Changeset{} = Reporting.change_report_card(report_card)
    end
  end
end
