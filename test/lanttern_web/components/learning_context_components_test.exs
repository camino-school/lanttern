defmodule LantternWeb.LearningContextComponentsTest do
  use Lanttern.DataCase, async: true

  import Phoenix.LiveViewTest
  import Lanttern.Factory

  alias LantternWeb.LearningContextComponents

  describe "strand_card/1 lock badge" do
    test "renders a lock badge when the strand is locked and show_lock is enabled" do
      strand = insert(:strand, is_locked: true) |> Repo.preload([:subjects, :years])

      html =
        render_component(&LearningContextComponents.strand_card/1,
          strand: strand,
          show_lock: true
        )

      assert html =~ "Locked"
    end

    test "does not render the badge when show_lock is enabled but the strand is unlocked" do
      strand = insert(:strand, is_locked: false) |> Repo.preload([:subjects, :years])

      html =
        render_component(&LearningContextComponents.strand_card/1,
          strand: strand,
          show_lock: true
        )

      refute html =~ "Locked"
    end

    test "does not render the badge on a locked strand when show_lock is not set (default)" do
      strand = insert(:strand, is_locked: true) |> Repo.preload([:subjects, :years])

      html = render_component(&LearningContextComponents.strand_card/1, strand: strand)

      refute html =~ "Locked"
    end
  end
end
