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

  - `bucket_id`: bucket name
  - `path`: The file path, including the file name. Should be of the format `folder/subfolder/filename.png`. The bucket must already exist before attempting to upload.
  - `file_path`: The **local** filesystem path, to upload from.
  - `opts`:An FileOptions consists of the following attributes:
    - `cache_control`: The number of seconds the asset is cached in the browser and in the Supabase CDN. This is set in the Cache-Control: max-age=<seconds> header. Defaults to 3600 seconds.
    - `content_type`: Specifies the media type of the resource or data. Default is "text/plain;charset=UTF-8".
    - `upsert`: When upsert is set to true, the file is overwritten if it exists. When set to false, an error is thrown if the object already exists. Defaults to false.
    - `metadata`: The metadata option is an object that allows you to store additional information about the file. This information can be used to filter and search for files. The metadata object can contain any key-value pairs you want to store.
    - `headers`: Optionally add extra headers to the request.
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

  def client, do: Supabase.init_client(config()[:base_url], config()[:api_key]) |> elem(1)

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

  @spec create_signed_url(url :: String.t()) :: {:ok, String.t()} | {:error, :invalid_url}
  def create_signed_url("https:" <> file_url) do
    bucket_name = "attachments"

    with [_, file] <- Regex.run(~r/attachments\/(.+)/, file_url),
         {:ok, signed_url} <- create_signed_url(file, bucket_name) do
      {:ok, signed_url}
    else
      _ -> {:error, :invalid_url}
    end
  end

  @spec create_signed_url(String.t(), String.t()) :: {:ok, String.t()} | {:error, :invalid_url}
  def create_signed_url(file, bucket_name \\ "attachments_private") do
    base_url = config()[:base_url]
    opts = [expires_in: 60]

    case Supabase.Storage.FileHandler.create_signed_url(client(), bucket_name, file, opts) do
      {:ok, %{body: body}} -> {:ok, "#{base_url}#{body["signedURL"]}"}
      _ -> {:error, :invalid_url}
    end
  end
end
