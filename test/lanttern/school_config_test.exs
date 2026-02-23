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
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})

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
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})

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
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})

      assert {:error, %Ecto.Changeset{}} =
               SchoolConfig.create_moment_card_template(scope, @invalid_attrs)
    end

    test "update_moment_card_template/2 with valid data updates the moment_card_template" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
      moment_card_template = moment_card_template_fixture(scope)
      update_attrs = %{name: "some updated name", position: 43, template: "some updated template"}

      assert {:ok, %MomentCardTemplate{} = moment_card_template} =
               SchoolConfig.update_moment_card_template(scope, moment_card_template, update_attrs)

      assert moment_card_template.name == "some updated name"
      assert moment_card_template.position == 43
      assert moment_card_template.template == "some updated template"
    end

    test "update_moment_card_template/2 with invalid data returns error changeset" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
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
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
      moment_card_template = moment_card_template_fixture(scope)

      assert {:ok, %MomentCardTemplate{}} =
               SchoolConfig.delete_moment_card_template(scope, moment_card_template)

      assert_raise Ecto.NoResultsError, fn ->
        SchoolConfig.get_moment_card_template!(scope, moment_card_template.id)
      end
    end

    test "change_moment_card_template/1 returns a moment_card_template changeset" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
      moment_card_template = moment_card_template_fixture(scope)

      assert %Ecto.Changeset{} =
               SchoolConfig.change_moment_card_template(scope, moment_card_template)
    end
  end

  describe "ai_configs" do
    alias Lanttern.IdentityFixtures
    alias Lanttern.SchoolConfig.AiConfig

    import Lanttern.Factory

    test "get_ai_config/1 returns ai_config for scope's school when exists" do
      scope = IdentityFixtures.scope_fixture()
      school = Lanttern.Schools.get_school!(scope.school_id)
      ai_config = insert(:ai_config, school: school)

      assert %AiConfig{id: id} = SchoolConfig.get_ai_config(scope)
      assert id == ai_config.id
    end

    test "get_ai_config/1 returns nil when no config exists for school" do
      scope = IdentityFixtures.scope_fixture()

      assert SchoolConfig.get_ai_config(scope) == nil
    end

    test "get_ai_config/1 returns nil when scope has no school_id" do
      scope = %Lanttern.Identity.Scope{school_id: nil}

      assert SchoolConfig.get_ai_config(scope) == nil
    end

    test "create_ai_config/2 creates ai_config with valid data and agents_management permission" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["agents_management"]})

      valid_attrs = %{
        "base_model" => "gpt-5-mini",
        "knowledge" => "School-wide knowledge base",
        "guardrails" => "Stay safe"
      }

      assert {:ok, %AiConfig{} = ai_config} = SchoolConfig.create_ai_config(scope, valid_attrs)
      assert ai_config.base_model == "gpt-5-mini"
      assert ai_config.knowledge == "School-wide knowledge base"
      assert ai_config.guardrails == "Stay safe"
      assert ai_config.school_id == scope.school_id
    end

    test "create_ai_config/2 with empty attrs still creates valid config with school_id from scope" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["agents_management"]})

      # Even with empty attrs, create_ai_config adds school_id from scope
      assert {:ok, %AiConfig{} = ai_config} = SchoolConfig.create_ai_config(scope, %{})
      assert ai_config.school_id == scope.school_id
      assert ai_config.base_model == nil
      assert ai_config.knowledge == nil
      assert ai_config.guardrails == nil
    end

    test "create_ai_config/2 raises without agents_management permission" do
      scope = IdentityFixtures.scope_fixture()

      valid_attrs = %{"base_model" => "gpt-5-mini"}

      assert_raise MatchError, fn ->
        SchoolConfig.create_ai_config(scope, valid_attrs)
      end
    end

    test "create_ai_config/2 enforces unique constraint on school_id" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["agents_management"]})
      school = Lanttern.Schools.get_school!(scope.school_id)

      # Insert existing ai_config for this school
      insert(:ai_config, school: school)

      valid_attrs = %{"base_model" => "gpt-5-mini"}

      assert {:error, %Ecto.Changeset{errors: errors}} =
               SchoolConfig.create_ai_config(scope, valid_attrs)

      assert {:school_id, _} = List.keyfind(errors, :school_id, 0)
    end

    test "update_ai_config/3 updates ai_config with valid data and agents_management permission" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["agents_management"]})
      school = Lanttern.Schools.get_school!(scope.school_id)
      ai_config = insert(:ai_config, school: school)

      update_attrs = %{
        "base_model" => "gpt-5-nano",
        "knowledge" => "Updated knowledge",
        "guardrails" => "Updated guardrails"
      }

      assert {:ok, %AiConfig{} = updated_config} =
               SchoolConfig.update_ai_config(scope, ai_config, update_attrs)

      assert updated_config.base_model == "gpt-5-nano"
      assert updated_config.knowledge == "Updated knowledge"
      assert updated_config.guardrails == "Updated guardrails"
    end

    test "update_ai_config/3 raises without agents_management permission" do
      scope = IdentityFixtures.scope_fixture()
      school = Lanttern.Schools.get_school!(scope.school_id)
      ai_config = insert(:ai_config, school: school)

      update_attrs = %{"base_model" => "gpt-5-nano"}

      assert_raise MatchError, fn ->
        SchoolConfig.update_ai_config(scope, ai_config, update_attrs)
      end
    end

    test "change_ai_config/3 returns a changeset" do
      scope = IdentityFixtures.scope_fixture()
      ai_config = build(:ai_config)

      assert %Ecto.Changeset{} = SchoolConfig.change_ai_config(scope, ai_config)
    end

    test "change_ai_config/3 returns a changeset with attrs" do
      scope = IdentityFixtures.scope_fixture()
      ai_config = build(:ai_config)
      attrs = %{"base_model" => "new-model"}

      changeset = SchoolConfig.change_ai_config(scope, ai_config, attrs)

      assert %Ecto.Changeset{} = changeset
      assert Ecto.Changeset.get_change(changeset, :base_model) == "new-model"
    end
  end
end
