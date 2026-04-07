defmodule Lanttern.ReqLLMErrorStub do
  @moduledoc """
  Error stub for `ReqLLM`-dependent tests.
  """

  def generate_text(_model, _context, _opts \\ []) do
    {:error, "API error"}
  end

  def generate_object(_model, _prompt, _schema) do
    {:error, "API error"}
  end
end
