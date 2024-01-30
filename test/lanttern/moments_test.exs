defmodule Lanttern.MomentsTest do
  use Lanttern.DataCase

  alias Lanttern.Moments

  describe "moment_cards" do
    alias Lanttern.Moments.MomentCard

    import Lanttern.MomentsFixtures

    @invalid_attrs %{name: nil, position: nil, description: nil}

    test "list_moment_cards/0 returns all moment_cards" do
      moment_card = moment_card_fixture()
      assert Moments.list_moment_cards() == [moment_card]
    end

    test "get_moment_card!/1 returns the moment_card with given id" do
      moment_card = moment_card_fixture()
      assert Moments.get_moment_card!(moment_card.id) == moment_card
    end

    test "create_moment_card/1 with valid data creates a moment_card" do
      moment = Lanttern.LearningContextFixtures.moment_fixture()

      valid_attrs = %{
        name: "some name",
        position: 42,
        description: "some description",
        moment_id: moment.id
      }

      assert {:ok, %MomentCard{} = moment_card} = Moments.create_moment_card(valid_attrs)
      assert moment_card.name == "some name"
      assert moment_card.position == 42
      assert moment_card.description == "some description"
      assert moment_card.moment_id == moment.id
    end

    test "create_moment_card/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Moments.create_moment_card(@invalid_attrs)
    end

    test "update_moment_card/2 with valid data updates the moment_card" do
      moment_card = moment_card_fixture()

      update_attrs = %{
        name: "some updated name",
        position: 43,
        description: "some updated description"
      }

      assert {:ok, %MomentCard{} = moment_card} =
               Moments.update_moment_card(moment_card, update_attrs)

      assert moment_card.name == "some updated name"
      assert moment_card.position == 43
      assert moment_card.description == "some updated description"
    end

    test "update_moment_card/2 with invalid data returns error changeset" do
      moment_card = moment_card_fixture()
      assert {:error, %Ecto.Changeset{}} = Moments.update_moment_card(moment_card, @invalid_attrs)
      assert moment_card == Moments.get_moment_card!(moment_card.id)
    end

    test "delete_moment_card/1 deletes the moment_card" do
      moment_card = moment_card_fixture()
      assert {:ok, %MomentCard{}} = Moments.delete_moment_card(moment_card)
      assert_raise Ecto.NoResultsError, fn -> Moments.get_moment_card!(moment_card.id) end
    end

    test "change_moment_card/1 returns a moment_card changeset" do
      moment_card = moment_card_fixture()
      assert %Ecto.Changeset{} = Moments.change_moment_card(moment_card)
    end
  end
end
