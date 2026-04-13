defmodule Lanttern.LLMStub do
  @moduledoc """
  Stub for `Lanttern.LLM`-dependent tests.
  """

  @behaviour Lanttern.LLM

  alias Lanttern.LLM.Response

  def generate_text(_model, _messages, _opts \\ []) do
    {:ok,
     %Response{
       text: "This is a stub response.",
       usage: %{input_tokens: 10, output_tokens: 20},
       messages: []
     }}
  end

  def generate_text_with_tools(_model, _messages, _tools, _opts \\ []) do
    {:ok,
     %Response{
       text: "This is a stub response.",
       usage: %{input_tokens: 10, output_tokens: 20},
       messages: []
     }}
  end

  def generate_object(_model, _prompt, _schema, _opts \\ []) do
    {:ok,
     %Response{
       object: %{"title" => "Stub Title"},
       usage: %{input_tokens: 10, output_tokens: 20}
     }}
  end
end

defmodule Lanttern.LLMErrorStub do
  @moduledoc """
  Error stub for `Lanttern.LLM`-dependent tests.
  """

  @behaviour Lanttern.LLM

  def generate_text(_model, _messages, _opts \\ []), do: {:error, "API error"}
  def generate_text_with_tools(_model, _messages, _tools, _opts \\ []), do: {:error, "API error"}
  def generate_object(_model, _prompt, _schema, _opts \\ []), do: {:error, "API error"}
end
