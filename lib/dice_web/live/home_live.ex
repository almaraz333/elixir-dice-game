defmodule DiceWeb.HomeLive do
  use DiceWeb, :live_view

  embed_templates "../templates/home_html/*"

  def render(assigns) do
    home(assigns)
  end
end
