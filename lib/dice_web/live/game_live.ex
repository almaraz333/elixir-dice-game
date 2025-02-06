defmodule DiceWeb.GameLive do
  use DiceWeb, :live_view

  embed_templates "../templates/game_html/*"

  def mount(%{"id" => room_id}, _session, socket) do
    if connected?(socket) do
      DiceWeb.Endpoint.subscribe("room:" <> room_id)

      DiceWeb.Endpoint.broadcast!(
        "room:" <> room_id,
        "log",
        %{player_id: socket.id, action: "join"}
      )
    end

    dice_options = ["Which Die?", 1, 2, 3, 4, 5, 6]
    amount_options = ["How many?"] ++ Enum.to_list(1..24)

    form_state = %{
      die_value: nil,
      amount_value: nil,
      dice_options: dice_options,
      amount_options: amount_options
    }

    game_state = %{
      curr_turn_player_id: nil,
      dice: nil,
      players: %{},
      player_id: socket.id,
      is_curr_players_turn: false,
      room_id: room_id,
      logs: []
    }

    socket =
      socket
      |> assign(:form_state, form_state)
      |> assign(:game_state, game_state)

    {:ok, socket}
  end

  def render(assigns) do
    case assigns.live_action do
      :index -> index(assigns)
    end
  end

  def handle_event("call-clicked", _value, socket) do
    {:noreply, socket}
  end

  def handle_event("submit-clicked", _value, socket) do
    {:noreply, socket}
  end

  def handle_event("form_change", value, socket) do
    %{"dice_option" => die_option, "amount_option" => amount_option} =
      value

    IO.inspect(value)

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

  # def handle_event("ready-clicked", _value, socket) do
  #   DiceWeb.Endpoint.broadcast!(
  #     # self(),
  #     "room:" <> socket.assigns.game_state.room_id,
  #     "log",
  #     %{player_id: socket.id, action: "join"}
  #   )

  #   {:noreply, socket}
  # end

  def handle_event("roll-dice", _value, socket) do
    dice = Enum.map(1..5, fn _ -> :rand.uniform(6) end)

    DiceWeb.Endpoint.broadcast!(
      "room:" <> socket.assigns.game_state.room_id,
      "log",
      %{player_id: socket.assigns.game_state.player_id, action: "roll"}
    )

    socket =
      socket
      |> update(:game_state, fn state -> Map.put(state, :dice, dice) end)

    {:noreply, socket}
  end

  def handle_event(
        "bid",
        %{"amount_option" => amount_option, "dice_option" => dice_option},
        socket
      ) do
    DiceWeb.Endpoint.broadcast!(
      "room:" <> socket.assigns.game_state.room_id,
      "log",
      %{
        player_id: socket.assigns.game_state.player_id,
        amount: amount_option,
        die_value: dice_option,
        action: "bid"
      }
    )

    {:noreply, socket}
  end

  def handle_info(%{event: "log", payload: payload}, socket) do
    curr_logs = socket.assigns.game_state.logs

    socket =
      case payload.action do
        "roll" ->
          new_logs = curr_logs ++ ["User #{payload.player_id} has rolled"]
          update(socket, :game_state, fn state -> Map.put(state, :logs, new_logs) end)

        "bid" ->
          new_logs =
            curr_logs ++
              ["User #{payload.player_id} has bid #{payload.amount} #{payload.die_value}(s)"]

          update(socket, :game_state, fn state -> Map.put(state, :logs, new_logs) end)

        "join" ->
          new_logs =
            curr_logs ++
              ["User #{payload.player_id} has joined"]

          update(socket, :game_state, fn state -> Map.put(state, :logs, new_logs) end)
          |> update(:game_state, fn state ->
            %{state | :players => Map.put(state.players, payload.player_id, "joined")}
          end)

        _ ->
          socket
      end

    {:noreply, socket}
  end
end
