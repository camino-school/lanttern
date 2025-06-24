defmodule Lanttern.SupabaseHelpers do
  @moduledoc """
  Wrapper around `Supabase` for ease of use
  """

  @doc """
  `Supabase.Storage.create_bucket/2` wrapper.
  -
  This wrapper:

  - handles the client
  - puts the bucket name into valid attrs
  """
  def create_bucket(bucket_name) do
    Supabase.Storage.create_bucket(client(), bucket_name, %{public: true})
  end

  @doc """
  `Supabase.Storage.File.upload/3` wrapper.
  """
  def upload_object(bucket_id, path, file_path, opts \\ %{}) do
    object_path =
      "#{Ecto.UUID.generate()}-#{path}"
      |> Slug.slugify(lowercase: false, ignore: "._")
      |> URI.encode()

    client()
    |> Supabase.Storage.from(bucket_id)
    |> Supabase.Storage.File.upload(file_path, object_path, opts)
  end

  @doc """
  `Supabase.Storage.File.remove/1` wrapper.

  This wrapper:

  - handles the client
  - created storage into a `Supabase.Storage` struct
  - extract the wildcard from URL and builds a Supabase.Storage.Object
  """
  def remove_object(bucket_id, url) do
    path =
      case Regex.run(~r/.*\/([^?]+)/, url) do
        [_, match] -> match
        nil -> nil
      end

    client()
    |> Supabase.Storage.from(bucket_id)
    |> Supabase.Storage.File.remove(path)
  end

  defp client, do: Supabase.init_client(config()[:base_url], config()[:api_key]) |> elem(1)

  @doc """
  Returns a map with `base_url` and `api_key`.

  Useful for building object urls.

      > "\#{config()[:base_url]}/storage/v1/object/public/bucket/object_path"
  """
  def config do
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

  # # uncomment to skip image transformation in dev env
  # def object_url_to_render_url(url, opts) when is_binary(url), do: url

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
