defmodule Lanttern.LearningContextTest do
  use Lanttern.DataCase

  alias Lanttern.LearningContext
  import Lanttern.LearningContextFixtures

  describe "strands" do
    alias Lanttern.LearningContext.Strand

    import Lanttern.TaxonomyFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_strands/1 returns all strands ordered alphabetically" do
      strand_a = strand_fixture(%{name: "AAA"})
      strand_c = strand_fixture(%{name: "CCC"})
      strand_b = strand_fixture(%{name: "BBB"})

      {results, _meta} = LearningContext.list_strands()
      assert results == [strand_a, strand_b, strand_c]
    end

    test "list_strands/1 with pagination opts returns all strands ordered alphabetically and paginated" do
      strand_a = strand_fixture(%{name: "AAA"})
      strand_c = strand_fixture(%{name: "CCC"})
      strand_b = strand_fixture(%{name: "BBB"})
      strand_d = strand_fixture(%{name: "DDD"})
      strand_e = strand_fixture(%{name: "EEE"})
      strand_f = strand_fixture(%{name: "FFF"})

      {results, meta} = LearningContext.list_strands(first: 5)

      assert results == [
               strand_a,
               strand_b,
               strand_c,
               strand_d,
               strand_e
             ]

      {results, _meta} = LearningContext.list_strands(first: 5, after: meta.end_cursor)

      assert results == [strand_f]
    end

    test "list_strands/1 with preloads and filters returns all filtered strands with preloaded data" do
      subject = subject_fixture()
      year = year_fixture()
      strand = strand_fixture(%{subjects_ids: [subject.id], years_ids: [year.id]})

      # extra strands for filtering
      strand_fixture()
      strand_fixture(%{subjects_ids: [subject.id]})
      strand_fixture(%{years_ids: [year.id]})

      {[expected], _meta} =
        LearningContext.list_strands(
          subjects_ids: [subject.id],
          years_ids: [year.id],
          preloads: [:subjects, :years]
        )

      assert expected.id == strand.id
      assert expected.subjects == [subject]
      assert expected.years == [year]
    end

    test "list_strands/1 with show_starred_for_profile_id returns all strands with is_starred field" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()
      strand_a = strand_fixture(%{name: "AAA"})
      strand_b = strand_fixture(%{name: "BBB"})

      # star strand a
      LearningContext.star_strand(strand_a.id, profile.id)

      {[expected_a, expected_b], _meta} =
        LearningContext.list_strands(show_starred_for_profile_id: profile.id)

      assert expected_a.id == strand_a.id
      assert expected_a.is_starred == true
      assert expected_b.id == strand_b.id
      assert expected_b.is_starred == false
    end

    test "search_strands/2 returns all items matched by search" do
      _strand_1 = strand_fixture(%{name: "lorem ipsum xolor sit amet"})
      strand_2 = strand_fixture(%{name: "lorem ipsum dolor sit amet"})
      strand_3 = strand_fixture(%{name: "lorem ipsum dolorxxx sit amet"})
      _strand_4 = strand_fixture(%{name: "lorem ipsum xxxxx sit amet"})

      expected = LearningContext.search_strands("dolor")

      assert length(expected) == 2

      # assert order
      assert [strand_2, strand_3] == expected
    end

    test "get_strand!/2 returns the strand with given id" do
      strand = strand_fixture()
      assert LearningContext.get_strand!(strand.id) == strand
    end

    test "get_strand!/2 with preloads returns the strand with given id and preloaded data" do
      subject = subject_fixture()
      year = year_fixture()
      strand = strand_fixture(%{subjects_ids: [subject.id], years_ids: [year.id]})

      expected = LearningContext.get_strand!(strand.id, preloads: [:subjects, :years])
      assert expected.id == strand.id
      assert expected.subjects == [subject]
      assert expected.years == [year]
    end

    test "create_strand/1 with valid data creates a strand" do
      subject = subject_fixture()
      year = year_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        subjects_ids: [subject.id],
        years_ids: [year.id]
      }

      assert {:ok, %Strand{} = strand} = LearningContext.create_strand(valid_attrs)
      assert strand.name == "some name"
      assert strand.description == "some description"
      assert strand.subjects == [subject]
      assert strand.years == [year]
    end

    test "create_strand/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LearningContext.create_strand(@invalid_attrs)
    end

    test "update_strand/2 with valid data updates the strand" do
      subject = subject_fixture()
      year_1 = year_fixture()
      year_2 = year_fixture()

      # subject is irrevelant, should be replaced
      # year is revelant, we'll keep it after update
      strand =
        strand_fixture(%{
          subjects_ids: [subject_fixture().id],
          years_ids: [year_1.id]
        })

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        subjects_ids: [subject.id],
        years_ids: [year_1.id, year_2.id]
      }

      assert {:ok, %Strand{} = strand} = LearningContext.update_strand(strand, update_attrs)
      assert strand.name == "some updated name"
      assert strand.description == "some updated description"
      assert strand.subjects == [subject]
      assert strand.years == [year_1, year_2] || strand.years == [year_2, year_1]
    end

    test "update_strand/2 with invalid data returns error changeset" do
      strand = strand_fixture()
      assert {:error, %Ecto.Changeset{}} = LearningContext.update_strand(strand, @invalid_attrs)
      assert strand == LearningContext.get_strand!(strand.id)
    end

    test "delete_strand/1 deletes the strand" do
      strand = strand_fixture()
      assert {:ok, %Strand{}} = LearningContext.delete_strand(strand)
      assert_raise Ecto.NoResultsError, fn -> LearningContext.get_strand!(strand.id) end
    end

    test "change_strand/1 returns a strand changeset" do
      strand = strand_fixture()
      assert %Ecto.Changeset{} = LearningContext.change_strand(strand)
    end
  end

  describe "starred strands" do
    alias Lanttern.LearningContext.Strand

    import Lanttern.IdentityFixtures
    import Lanttern.TaxonomyFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_starred_strands/1 returns all starred strands ordered alphabetically" do
      profile = teacher_profile_fixture()
      strand_b = strand_fixture(%{name: "BBB"}) |> Map.put(:is_starred, true)
      strand_a = strand_fixture(%{name: "AAA"}) |> Map.put(:is_starred, true)

      # extra strand to test filtering
      strand_fixture()

      # star strands a and b
      LearningContext.star_strand(strand_a.id, profile.id)
      LearningContext.star_strand(strand_b.id, profile.id)

      assert [strand_a, strand_b] == LearningContext.list_starred_strands(profile.id)
    end

    test "list_strands/1 with preloads and filters returns all filtered strands with preloaded data" do
      profile = teacher_profile_fixture()
      subject = subject_fixture()
      year = year_fixture()
      strand = strand_fixture(%{subjects_ids: [subject.id], years_ids: [year.id]})

      # extra strands for filtering
      other_strand = strand_fixture()
      strand_fixture(%{subjects_ids: [subject.id], years_ids: [year.id]})

      # star strand
      LearningContext.star_strand(strand.id, profile.id)
      LearningContext.star_strand(other_strand.id, profile.id)

      [expected] =
        LearningContext.list_starred_strands(
          profile.id,
          subjects_ids: [subject.id],
          years_ids: [year.id],
          preloads: [:subjects, :years]
        )

      assert expected.id == strand.id
      assert expected.subjects == [subject]
      assert expected.years == [year]
    end

    test "star_strand/2 and unstar_strand/2 functions as expected" do
      profile = teacher_profile_fixture()
      strand_a = strand_fixture(%{name: "AAA"}) |> Map.put(:is_starred, true)
      strand_b = strand_fixture(%{name: "BBB"}) |> Map.put(:is_starred, true)

      # empty list before starring
      assert [] == LearningContext.list_starred_strands(profile.id)

      # star and list again
      LearningContext.star_strand(strand_a.id, profile.id)
      LearningContext.star_strand(strand_b.id, profile.id)
      assert [strand_a, strand_b] == LearningContext.list_starred_strands(profile.id)

      # staring an already starred strand shouldn't cause any change
      assert {:ok, _starred_strand} = LearningContext.star_strand(strand_a.id, profile.id)
      assert [strand_a, strand_b] == LearningContext.list_starred_strands(profile.id)

      # unstar and list
      LearningContext.unstar_strand(strand_a.id, profile.id)
      assert [strand_b] == LearningContext.list_starred_strands(profile.id)
    end
  end

  describe "moments" do
    alias Lanttern.LearningContext.Moment

    import Lanttern.TaxonomyFixtures

    @invalid_attrs %{name: nil, position: nil, description: nil}

    test "list_moments/1 returns all moments" do
      moment = moment_fixture()
      assert LearningContext.list_moments() == [moment]
    end

    test "list_moments/1 with preloads returns all moments with preloaded data" do
      strand = strand_fixture()
      subject = subject_fixture()
      moment = moment_fixture(%{strand_id: strand.id, subjects_ids: [subject.id]})

      [expected] = LearningContext.list_moments(preloads: [:subjects, :strand])
      assert expected.id == moment.id
      assert expected.strand == strand
      assert expected.subjects == [subject]
    end

    test "list_moments/1 with strands filter returns moments filtered" do
      strand = strand_fixture()
      subject = subject_fixture()
      moment = moment_fixture(%{strand_id: strand.id, subjects_ids: [subject.id]})

      # extra moments for filter testing
      moment_fixture()
      moment_fixture()

      [expected] = LearningContext.list_moments(strands_ids: [strand.id], preloads: :subjects)
      assert expected.id == moment.id
      assert expected.subjects == [subject]
    end

    test "get_moment!/2 returns the moment with given id" do
      moment = moment_fixture()
      assert LearningContext.get_moment!(moment.id) == moment
    end

    test "get_moment!/2 with preloads returns the moment with given id and preloaded data" do
      strand = strand_fixture()
      subject = subject_fixture()
      moment = moment_fixture(%{strand_id: strand.id, subjects_ids: [subject.id]})

      expected = LearningContext.get_moment!(moment.id, preloads: [:strand, :subjects])
      assert expected.id == moment.id
      assert expected.strand == strand
      assert expected.subjects == [subject]
    end

    test "create_moment/1 with valid data creates a moment" do
      subject = subject_fixture()

      valid_attrs = %{
        name: "some name",
        position: 42,
        description: "some description",
        strand_id: strand_fixture().id,
        subjects_ids: [subject.id]
      }

      assert {:ok, %Moment{} = moment} = LearningContext.create_moment(valid_attrs)
      assert moment.name == "some name"
      assert moment.position == 42
      assert moment.description == "some description"
      assert moment.subjects == [subject]
    end

    test "create_moment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LearningContext.create_moment(@invalid_attrs)
    end

    test "update_moment/2 with valid data updates the moment" do
      moment = moment_fixture(%{subjects_ids: [subject_fixture().id]})
      subject = subject_fixture()

      update_attrs = %{
        name: "some updated name",
        position: 43,
        description: "some updated description",
        subjects_ids: [subject.id]
      }

      assert {:ok, %Moment{} = moment} =
               LearningContext.update_moment(moment, update_attrs)

      assert moment.name == "some updated name"
      assert moment.position == 43
      assert moment.description == "some updated description"
      assert moment.subjects == [subject]
    end

    test "update_moment/2 with invalid data returns error changeset" do
      moment = moment_fixture()

      assert {:error, %Ecto.Changeset{}} =
               LearningContext.update_moment(moment, @invalid_attrs)

      assert moment == LearningContext.get_moment!(moment.id)
    end

    test "update_strand_moments_positions/2 update strand moments position based on list order" do
      strand = strand_fixture()
      moment_1 = moment_fixture(%{strand_id: strand.id})
      moment_2 = moment_fixture(%{strand_id: strand.id})
      moment_3 = moment_fixture(%{strand_id: strand.id})
      moment_4 = moment_fixture(%{strand_id: strand.id})

      sorted_moments_ids =
        [
          moment_2.id,
          moment_3.id,
          moment_1.id,
          moment_4.id
        ]

      assert {:ok,
              [
                expected_2,
                expected_3,
                expected_1,
                expected_4
              ]} =
               LearningContext.update_strand_moments_positions(
                 strand.id,
                 sorted_moments_ids
               )

      assert expected_1.id == moment_1.id
      assert expected_2.id == moment_2.id
      assert expected_3.id == moment_3.id
      assert expected_4.id == moment_4.id
    end

    test "delete_moment/1 deletes the moment" do
      moment = moment_fixture()
      assert {:ok, %Moment{}} = LearningContext.delete_moment(moment)
      assert_raise Ecto.NoResultsError, fn -> LearningContext.get_moment!(moment.id) end
    end

    test "change_moment/1 returns a moment changeset" do
      moment = moment_fixture()
      assert %Ecto.Changeset{} = LearningContext.change_moment(moment)
    end
  end

  describe "moment_cards" do
    alias Lanttern.LearningContext.MomentCard

    import Lanttern.LearningContextFixtures

    @invalid_attrs %{name: nil, position: nil, description: nil}

    test "list_moment_cards/1 returns all moment_cards" do
      moment_card = moment_card_fixture()
      assert LearningContext.list_moment_cards() == [moment_card]
    end

    test "list_moment_cards/1 with moments filter returns moment cards filtered and ordered by position" do
      moment = moment_fixture()

      # create moment card should handle positioning
      moment_card_1 = moment_card_fixture(%{moment_id: moment.id})
      moment_card_2 = moment_card_fixture(%{moment_id: moment.id})

      # extra moment cards for filter testing
      moment_card_fixture()
      moment_card_fixture()

      assert [moment_card_1, moment_card_2] ==
               LearningContext.list_moment_cards(moments_ids: [moment.id])
    end

    test "get_moment_card!/1 returns the moment_card with given id" do
      moment_card = moment_card_fixture()
      assert LearningContext.get_moment_card!(moment_card.id) == moment_card
    end

    test "create_moment_card/1 with valid data creates a moment_card" do
      moment = moment_fixture()

      valid_attrs = %{
        name: "some name",
        position: 42,
        description: "some description",
        moment_id: moment.id
      }

      assert {:ok, %MomentCard{} = moment_card} = LearningContext.create_moment_card(valid_attrs)
      assert moment_card.name == "some name"
      assert moment_card.position == 42
      assert moment_card.description == "some description"
      assert moment_card.moment_id == moment.id
    end

    test "create_moment_card/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LearningContext.create_moment_card(@invalid_attrs)
    end

    test "update_moment_card/2 with valid data updates the moment_card" do
      moment_card = moment_card_fixture()

      update_attrs = %{
        name: "some updated name",
        position: 43,
        description: "some updated description"
      }

      assert {:ok, %MomentCard{} = moment_card} =
               LearningContext.update_moment_card(moment_card, update_attrs)

      assert moment_card.name == "some updated name"
      assert moment_card.position == 43
      assert moment_card.description == "some updated description"
    end

    test "update_moment_card/2 with invalid data returns error changeset" do
      moment_card = moment_card_fixture()

      assert {:error, %Ecto.Changeset{}} =
               LearningContext.update_moment_card(moment_card, @invalid_attrs)

      assert moment_card == LearningContext.get_moment_card!(moment_card.id)
    end

    test "delete_moment_card/1 deletes the moment_card" do
      moment_card = moment_card_fixture()
      assert {:ok, %MomentCard{}} = LearningContext.delete_moment_card(moment_card)
      assert_raise Ecto.NoResultsError, fn -> LearningContext.get_moment_card!(moment_card.id) end
    end

    test "change_moment_card/1 returns a moment_card changeset" do
      moment_card = moment_card_fixture()
      assert %Ecto.Changeset{} = LearningContext.change_moment_card(moment_card)
    end
  end
end
