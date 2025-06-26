defmodule Lanttern.Repo.Migrations.AddProfilePictureUrlToStudents do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :profile_picture_url, :text
    end

    # set the last student cycle info profile picture URL
    # as the initial student profile_picture_url value
    execute """
            update students s
            set profile_picture_url = last_sci.profile_picture_url
            from (
              select
                distinct on (sci.student_id, sc.end_at, sc.start_at)
                sci.*
              from students_cycle_info sci
              join school_cycles sc on sc.id = sci.cycle_id
              where sci.profile_picture_url is not null
              order by sc.end_at desc, sc.start_at asc
            ) as last_sci
            where last_sci.student_id = s.id
            """,
            ""
  end
end
