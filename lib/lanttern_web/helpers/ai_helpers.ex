defmodule LantternWeb.AIHelpers do
  @moduledoc """
  Helper functions related to AI implementation
  """

  @doc """
  Generate the list of AI models to use as `Phoenix.HTML.Form.options_for_select/2` arg.

  Will list all OpenAI available models - if, for some reason, the current model is
  not in the returned list, it will be added to the list.

  ## Examples

      iex> generate_ai_model_options()
      ["model_id": "model_id", ...]
  """
  def generate_ai_model_options(current \\ nil) do
    models =
      case ExOpenAI.Models.list_models() do
        {:ok, %ExOpenAI.Components.ListModelsResponse{data: data}} ->
          Enum.map(data, & &1.id)

        _ ->
          []
      end

    models =
      if current && !Enum.member?(models, current) do
        [current | models]
      else
        models
      end

    models
    |> Enum.map(fn m -> {m, m} end)
  end
end
