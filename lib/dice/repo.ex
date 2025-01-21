defmodule Dice.Repo do
  use Ecto.Repo,
    otp_app: :dice,
    adapter: Ecto.Adapters.SQLite3
end
