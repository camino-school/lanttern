defmodule LantternWeb.FormHelpers do
  @moduledoc """
  Helper functions related to forms
  """

  alias Lanttern.SupabaseHelpers

  @doc """
  Consumes uploaded profile picture and uploads to Supabase storage.

  Process the image before uploading (thumbnail with 640px),
  and returns the uploaded file image URL or `nil` if there is no uploaded file.

  This function also handles the cleanup of the temporary thumbnail folder.
  """
  @spec consume_uploaded_profile_picture(Phoenix.LiveView.Socket.t(), upload_name :: atom()) ::
          image_url :: String.t() | nil
  def consume_uploaded_profile_picture(socket, upload_name) do
    Phoenix.LiveView.consume_uploaded_entries(socket, upload_name, fn %{path: file_path}, entry ->
      # thumbnail image before upload to save space
      original_raw = File.read!(file_path)
      {:ok, original} = Image.from_binary(original_raw)
      {:ok, thumbnail} = Image.thumbnail(original, 640, crop: :center)
      thumbnail_folder = Path.join(System.tmp_dir(), Ecto.UUID.generate())
      :ok = File.mkdir!(thumbnail_folder)
      thumbnail_path = Path.join(thumbnail_folder, entry.client_name)

      try do
        {:ok, _} = Image.write(thumbnail, thumbnail_path)

        {:ok, object} =
          SupabaseHelpers.upload_object(
            "profile_pictures",
            entry.client_name,
            thumbnail_path,
            %{content_type: entry.client_type}
          )
          |> case do
            {:error, "Bucket not found"} ->
              # create bucket and retry
              {:ok, bucket} =
                SupabaseHelpers.create_bucket("profile_pictures")

              SupabaseHelpers.upload_object(
                bucket.name,
                entry.client_name,
                file_path,
                %{content_type: entry.client_type}
              )

            success_tuple ->
              success_tuple
          end

        image_url =
          "#{SupabaseHelpers.config().base_url}/storage/v1/object/public/#{URI.encode(object.key)}"

        {:ok, image_url}
      after
        # cleanup in async task (fire and forget)
        Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
          File.rm_rf(thumbnail_folder)
        end)
      end
    end)
    |> case do
      [] -> nil
      [image_url] -> image_url
    end
  end
end
