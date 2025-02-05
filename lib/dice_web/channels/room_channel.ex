defmodule DiceWeb.RoomChannel do
  use DiceWeb, :channel

  @impl true
  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end

  def join("room:" <> _id, _params, socket) do
    game_state = %{
      current_players_turn: nil,
      players: [],
      dice: [],
      bid: nil
    }

    send(self(), :after_join)

    socket =
      socket
      |> assign(game_state: game_state)

    {:ok, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    # broadcast!(socket, "player_joined", "Player #{socket.assigns.user_id} had joined.")
    IO.puts("USER JOINED")

    {:noreply, socket}
  end

  @impl true
  def handle_in("roll_dice", _payload, socket) do
    dice = Enum.map(1..5, fn _ -> :rand.uniform(6) end)

    socket =
      socket
      |> assign(:dice, dice)

    push(socket, "your_dice", %{dice: dice})

    {:reply, :ok, socket}
  end

  @impl true
  def handle_in("make_bid", %{"quantity" => quantity, "value" => value}, socket) do
    broadcast!(socket, "new_bid", %{
      user_id: socket.assigns.user_id,
      quantity: quantity,
      value: value
    })

    {:reply, :ok, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    IO.inspect(socket)

    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  # @impl true
  # def handle_in("shout", payload, socket) do
  #   broadcast(socket, "shout", payload)
  #   {:noreply, socket}
  # end

  def handle_in("new_msg_created", %{"body" => body}, socket) do
    broadcast!(socket, "new_msg_send", %{body: body})

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  # defp authorized?(_payload) do
  #   true
  # end
end
