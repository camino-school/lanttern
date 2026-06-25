defmodule LantternWeb.StrandsComponentsTest do
  use Lanttern.DataCase, async: true
  import Phoenix.LiveViewTest

  alias Lanttern.LearningContext.Strand
  alias Lanttern.Schools.StaffMember
  alias LantternWeb.StrandsComponents

  describe "strand_lock_bar/1" do
    test "renders nothing when the strand is not locked" do
      strand = %Strand{is_locked: false}

      html = render_component(&StrandsComponents.strand_lock_bar/1, strand: strand)

      refute html =~ "This strand is locked"
    end

    test "renders the indicator with provenance when the strand is locked" do
      strand = %Strand{
        is_locked: true,
        locked_at: ~U[2026-06-01 10:00:00Z],
        locked_by_staff_member: %StaffMember{name: "Coordinator Jane"}
      }

      html =
        render_component(&StrandsComponents.strand_lock_bar/1, strand: strand, tz: "Etc/UTC")

      assert html =~ "This strand is locked"
      assert html =~ "Locked by Coordinator Jane"
    end

    test "falls back to 'unknown staff member' when the staff member is not loaded" do
      strand = %Strand{
        is_locked: true,
        locked_at: ~U[2026-06-01 10:00:00Z],
        locked_by_staff_member: %Ecto.Association.NotLoaded{}
      }

      html =
        render_component(&StrandsComponents.strand_lock_bar/1, strand: strand, tz: "Etc/UTC")

      assert html =~ "Locked by unknown staff member"
    end
  end

  describe "lock_provenance_text/2" do
    test "returns nil when the strand is not locked" do
      assert StrandsComponents.lock_provenance_text(%Strand{is_locked: false}) == nil
    end

    test "includes the staff member name and date when both are present" do
      strand = %Strand{
        is_locked: true,
        locked_at: ~U[2026-06-01 10:00:00Z],
        locked_by_staff_member: %StaffMember{name: "Coordinator Jane"}
      }

      text = StrandsComponents.lock_provenance_text(strand, "Etc/UTC")

      assert text =~ "Locked by Coordinator Jane on"
    end

    test "omits the date when locked_at is missing" do
      strand = %Strand{
        is_locked: true,
        locked_at: nil,
        locked_by_staff_member: %StaffMember{name: "Coordinator Jane"}
      }

      assert StrandsComponents.lock_provenance_text(strand) == "Locked by Coordinator Jane"
    end
  end
end
