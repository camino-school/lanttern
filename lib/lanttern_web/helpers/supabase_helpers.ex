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

  @doc """
  Transforms a Supabase object url into a render url with transformations.

  https://supabase.github.io/storage/#/object/get_render_image_public__bucketName___wildcard_

  ## Options

  - `:width` - the transformation width
  - `:height` - the transformation height

  ## Examples

      iex> object_url_to_render_url("https://blah.supabase.co/storage/v1/object/public/bucket/path_to_file.jpg", width: 200, height: 100)
      "https://blah.supabase.co/storage/v1/object/public/bucket/path_to_file.jpg?width=200&height=100"
  """
  @spec object_url_to_render_url(url :: String.t() | nil, opts :: Keyword.t()) :: String.t() | nil

  def object_url_to_render_url(url, opts \\ [])

  def object_url_to_render_url(nil, _opts), do: nil

  def object_url_to_render_url(url, opts) when is_binary(url) do
    case Regex.match?(~r/\/object\/public/, url) do
      true ->
        url = Regex.replace(~r/\/object\/public/, url, "/render/image/public")
        "#{url}?#{transform_params(opts)}"

      _ ->
        url
    end
  end

  defp transform_params(opts, params \\ [])

  defp transform_params([], params), do: Enum.join(params, "&")

  defp transform_params([{:width, width} | opts], params),
    do: transform_params(opts, ["width=#{width}" | params])

  defp transform_params([{:height, height} | opts], params),
    do: transform_params(opts, ["height=#{height}" | params])
end
