defmodule Lanttern.SchoolConfigTest do
  use Lanttern.DataCase

  alias Lanttern.SchoolConfig

  describe "moment_cards_templates" do
    alias Lanttern.SchoolConfig.MomentCardTemplate

    import Lanttern.SchoolConfigFixtures

    alias Lanttern.IdentityFixtures

    @invalid_attrs %{name: nil, position: nil, template: nil}

    test "list_moment_cards_templates/1 returns all moment_cards_templates ordered by position" do
      scope = IdentityFixtures.scope_fixture()
      moment_card_template_3 = moment_card_template_fixture(scope, %{position: 3})
      moment_card_template_2 = moment_card_template_fixture(scope, %{position: 2})
      moment_card_template_1 = moment_card_template_fixture(scope, %{position: 1})

      # list should be filter by school scope. create other fixture for filter test
      moment_card_template_fixture(IdentityFixtures.scope_fixture())

      assert SchoolConfig.list_moment_cards_templates(scope) == [
               moment_card_template_1,
               moment_card_template_2,
               moment_card_template_3
             ]

      # use same setup to test update_moment_cards_templates_positions/1

      SchoolConfig.update_moment_cards_templates_positions([
        moment_card_template_2.id,
        moment_card_template_3.id,
        moment_card_template_1.id
      ])

      [
        expected_moment_card_template_2,
        expected_moment_card_template_3,
        expected_moment_card_template_1
      ] = SchoolConfig.list_moment_cards_templates(scope)

      assert expected_moment_card_template_1.id == moment_card_template_1.id
      assert expected_moment_card_template_2.id == moment_card_template_2.id
      assert expected_moment_card_template_3.id == moment_card_template_3.id
    end

    test "get_moment_card_template!/1 returns the moment_card_template with given id" do
      scope = IdentityFixtures.scope_fixture()
      moment_card_template = moment_card_template_fixture(scope)

      assert SchoolConfig.get_moment_card_template!(scope, moment_card_template.id) ==
               moment_card_template
    end

    test "create_moment_card_template/1 with valid data creates a moment_card_template" do
      scope = IdentityFixtures.scope_fixture()

      valid_attrs = %{
        name: "some name",
        position: 42,
        template: "some template"
      }

      assert {:ok, %MomentCardTemplate{} = moment_card_template} =
               SchoolConfig.create_moment_card_template(scope, valid_attrs)

      assert moment_card_template.name == "some name"
      assert moment_card_template.position == 42
      assert moment_card_template.template == "some template"
    end

    test "created moments cards are ordered automatically" do
      scope = IdentityFixtures.scope_fixture()

      valid_attrs = %{
        name: "some name",
        template: "some template"
      }

      {:ok, _moment_card_template_1} =
        SchoolConfig.create_moment_card_template(scope, valid_attrs)

      {:ok, _moment_card_template_2} =
        SchoolConfig.create_moment_card_template(scope, valid_attrs)

      {:ok, _moment_card_template_3} =
        SchoolConfig.create_moment_card_template(scope, valid_attrs)

      [
        expected_moment_card_template_1,
        expected_moment_card_template_2,
        expected_moment_card_template_3
      ] = SchoolConfig.list_moment_cards_templates(scope)

      assert expected_moment_card_template_1.position == 0
      assert expected_moment_card_template_2.position == 1
      assert expected_moment_card_template_3.position == 2
    end

    test "create_moment_card_template/1 with invalid data returns error changeset" do
      scope = IdentityFixtures.scope_fixture()

      assert {:error, %Ecto.Changeset{}} =
               SchoolConfig.create_moment_card_template(scope, @invalid_attrs)
    end

    test "update_moment_card_template/2 with valid data updates the moment_card_template" do
      scope = IdentityFixtures.scope_fixture()
      moment_card_template = moment_card_template_fixture(scope)
      update_attrs = %{name: "some updated name", position: 43, template: "some updated template"}

      assert {:ok, %MomentCardTemplate{} = moment_card_template} =
               SchoolConfig.update_moment_card_template(scope, moment_card_template, update_attrs)

      assert moment_card_template.name == "some updated name"
      assert moment_card_template.position == 43
      assert moment_card_template.template == "some updated template"
    end

    test "update_moment_card_template/2 with invalid data returns error changeset" do
      scope = IdentityFixtures.scope_fixture()
      moment_card_template = moment_card_template_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               SchoolConfig.update_moment_card_template(
                 scope,
                 moment_card_template,
                 @invalid_attrs
               )

      assert moment_card_template ==
               SchoolConfig.get_moment_card_template!(scope, moment_card_template.id)
    end

    test "delete_moment_card_template/1 deletes the moment_card_template" do
      scope = IdentityFixtures.scope_fixture()
      moment_card_template = moment_card_template_fixture(scope)

      assert {:ok, %MomentCardTemplate{}} =
               SchoolConfig.delete_moment_card_template(scope, moment_card_template)

      assert_raise Ecto.NoResultsError, fn ->
        SchoolConfig.get_moment_card_template!(scope, moment_card_template.id)
      end
    end

    test "change_moment_card_template/1 returns a moment_card_template changeset" do
      scope = IdentityFixtures.scope_fixture()
      moment_card_template = moment_card_template_fixture(scope)

      assert %Ecto.Changeset{} =
               SchoolConfig.change_moment_card_template(scope, moment_card_template)
    end
  end
end
