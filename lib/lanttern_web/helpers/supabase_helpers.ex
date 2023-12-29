defmodule LantternWeb.SupabaseHelpers do
  @moduledoc """
  Wrapper around `Supabase` for ease of use
  """

  @client_name :lanttern

  @doc """
  `Supabase.Storage.upload_object/5` wrapper.

  This wrapper:

  - handles the client
  - puts the bucket name into a `Supabase.Storage.Bucket` struct
  - URI encodes the path
  - parses opts to a `Supabase.Storage.ObjectOptions` struct
  """
  def upload_object(bucket_name, path, file, opts \\ %{}) do
    client = client()

    Supabase.Storage.upload_object(
      client,
      Supabase.Storage.Bucket.parse!(%{name: bucket_name}),
      URI.encode(path),
      file,
      Supabase.Storage.ObjectOptions.parse!(opts)
    )
  end

  @doc """
  Returns a map with `base_url` and `api_key`.

  Useful for building object urls.

      > "\#{config().base_url}/storage/v1/object/public/bucket/object_path"
  """
  def config() do
    %{
      base_url: System.fetch_env!("SUPABASE_PROJECT_URL"),
      api_key: System.fetch_env!("SUPABASE_PROJECT_API_KEY")
    }
  end

  # helpers

  defp client() do
    Supabase.init_client(%{
      name: @client_name,
      conn: %{
        base_url: config().base_url,
        api_key: config().api_key
      }
    })
    |> case do
      {:error, {:already_started, pid}} -> pid
      {:ok, pid} -> pid
      res -> res
    end
  end
end
