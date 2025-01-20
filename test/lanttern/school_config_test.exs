defmodule Lanttern.SchoolConfigTest do
  use Lanttern.DataCase

  alias Lanttern.SchoolConfig

  describe "moment_cards_templates" do
    alias Lanttern.SchoolConfig.MomentCardTemplate

    import Lanttern.SchoolConfigFixtures

    @invalid_attrs %{name: nil, position: nil, template: nil}

    test "list_moment_cards_templates/0 returns all moment_cards_templates" do
      moment_card_template = moment_card_template_fixture()
      assert SchoolConfig.list_moment_cards_templates() == [moment_card_template]
    end

    test "get_moment_card_template!/1 returns the moment_card_template with given id" do
      moment_card_template = moment_card_template_fixture()

      assert SchoolConfig.get_moment_card_template!(moment_card_template.id) ==
               moment_card_template
    end

    test "create_moment_card_template/1 with valid data creates a moment_card_template" do
      school = Lanttern.SchoolsFixtures.school_fixture()

      valid_attrs = %{
        name: "some name",
        position: 42,
        template: "some template",
        school_id: school.id
      }

      assert {:ok, %MomentCardTemplate{} = moment_card_template} =
               SchoolConfig.create_moment_card_template(valid_attrs)

      assert moment_card_template.name == "some name"
      assert moment_card_template.position == 42
      assert moment_card_template.template == "some template"
    end

    test "create_moment_card_template/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               SchoolConfig.create_moment_card_template(@invalid_attrs)
    end

    test "update_moment_card_template/2 with valid data updates the moment_card_template" do
      moment_card_template = moment_card_template_fixture()
      update_attrs = %{name: "some updated name", position: 43, template: "some updated template"}

      assert {:ok, %MomentCardTemplate{} = moment_card_template} =
               SchoolConfig.update_moment_card_template(moment_card_template, update_attrs)

      assert moment_card_template.name == "some updated name"
      assert moment_card_template.position == 43
      assert moment_card_template.template == "some updated template"
    end

    test "update_moment_card_template/2 with invalid data returns error changeset" do
      moment_card_template = moment_card_template_fixture()

      assert {:error, %Ecto.Changeset{}} =
               SchoolConfig.update_moment_card_template(moment_card_template, @invalid_attrs)

      assert moment_card_template ==
               SchoolConfig.get_moment_card_template!(moment_card_template.id)
    end

    test "delete_moment_card_template/1 deletes the moment_card_template" do
      moment_card_template = moment_card_template_fixture()

      assert {:ok, %MomentCardTemplate{}} =
               SchoolConfig.delete_moment_card_template(moment_card_template)

      assert_raise Ecto.NoResultsError, fn ->
        SchoolConfig.get_moment_card_template!(moment_card_template.id)
      end
    end

    test "change_moment_card_template/1 returns a moment_card_template changeset" do
      moment_card_template = moment_card_template_fixture()
      assert %Ecto.Changeset{} = SchoolConfig.change_moment_card_template(moment_card_template)
    end
  end
end
