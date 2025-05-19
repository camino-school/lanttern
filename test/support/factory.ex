defmodule Lanttern.Factory do
  use ExMachina.Ecto, repo: Lanttern.Repo

  use Lanttern.MessageBoardFactory
  use Lanttern.SchoolFactory
end
