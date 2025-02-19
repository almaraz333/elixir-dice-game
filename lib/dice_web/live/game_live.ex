defmodule DiceWeb.GameLive do
  use DiceWeb, :live_view
  require Logger

  embed_templates "../templates/game_html/*"

  def mount(%{"id" => room_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Dice.PubSub, "room:#{room_id}")

      Dice.GameRoom.log(room_id, "Player #{socket.id} has joined.")
    end

    Dice.GameRoom.create_room(room_id)

    player_data = %{
      name: "Player #{socket.id}",
      joined_at: DateTime.utc_now(),
      dice: []
    }

    Dice.GameRoom.add_player(room_id, socket.id, player_data)

    gen_server_game_state = Dice.GameRoom.get_state(room_id)

    dice_options = ["Which Die?", 1, 2, 3, 4, 5, 6]
    amount_options = ["How many?"] ++ Enum.to_list(1..24)

    form_state = %{
      die_value: nil,
      amount_value: nil,
      dice_options: dice_options,
      amount_options: amount_options
    }

    socket =
      socket
      |> assign(:form_state, form_state)
      |> assign(:game_state, gen_server_game_state)
      |> assign(:player_id, socket.id)

    {:ok, socket}
  end

  def render(assigns) do
    case assigns.live_action do
      :index -> index(assigns)
    end
  end

  def handle_event("submit-clicked", _value, socket) do
    {:noreply, socket}
  end

  def handle_event("form_change", value, socket) do
    %{"dice_option" => die_option, "amount_option" => amount_option} =
      value

    socket =
      socket
      |> update(:form_state, fn state -> Map.put(state, :die_value, die_option) end)
      |> update(:form_state, fn state -> Map.put(state, :amount_value, amount_option) end)

    {:noreply, socket}
  end

  def handle_event("ping-clicked", _value, socket) do
    IO.inspect(socket.assigns)

    {:noreply, socket}
  end

  def handle_event("roll-dice", _value, socket) do
    Dice.GameRoom.roll_dice(socket.assigns.game_state.room_id, socket.id)
    Dice.GameRoom.log(socket.assigns.game_state.room_id, "Player #{socket.id} has rolled.")

    {:noreply, socket}
  end

  def handle_event(
        "bid",
        %{"amount_option" => amount_option, "dice_option" => dice_option},
        socket
      ) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:room_updated, room_id}, socket) do
    new_state = Dice.GameRoom.get_state(room_id)

    {:noreply, assign(socket, game_state: new_state)}
  end
end
