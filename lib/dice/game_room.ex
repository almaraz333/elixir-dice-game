defmodule Dice.GameRoom do
  use GenServer
  require Logger

  def start_link(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: via_tuple(room_id))
  end

  def create_room(room_id) do
    case DynamicSupervisor.start_child(
           Dice.GameRoomSupervisor,
           {__MODULE__, room_id}
         ) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      error -> error
    end
  end

  def get_state(room_id) do
    GenServer.call(via_tuple(room_id), :get_state)
  end

  def add_player(room_id, player_id, player_data) do
    GenServer.call(via_tuple(room_id), {:add_player, player_id, player_data})
  end

  def roll_dice(room_id, player_id) do
    dice = Enum.map(1..5, fn _ -> :rand.uniform(6) end)

    GenServer.call(via_tuple(room_id), {:roll_dice, player_id, dice})
  end

  def log(room_id, message) do
    GenServer.call(via_tuple(room_id), {:log, message})
  end

  defp via_tuple(room_id) do
    {:via, Registry, {Dice.GameRegistry, room_id}}
  end

  # CALLLBACKS
  @impl true
  def init(room_id) do
    Logger.info("Starting game room - #{room_id}")

    init_state = %{
      room_id: room_id,
      players: %{},
      created_at: DateTime.utc_now(),
      curr_turn_player_id: nil,
      logs: []
    }

    {:ok, init_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:add_player, player_id, player_data}, _from, state) do
    new_players = Map.put(state.players, player_id, player_data)

    new_state = %{state | players: new_players}

    Phoenix.PubSub.broadcast(Dice.PubSub, "room:#{state.room_id}", {:room_updated, state.room_id})

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:roll_dice, player_id, dice}, _from, state) do
    new_state = update_in(state, [:players, player_id, :dice], fn _ -> dice end)

    Phoenix.PubSub.broadcast(Dice.PubSub, "room:#{state.room_id}", {:room_updated, state.room_id})

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:log, message}, _from, state) do
    new_state = update_in(state, [:logs], fn logs -> [message | logs] end)

    Phoenix.PubSub.broadcast(Dice.PubSub, "room:#{state.room_id}", {:room_updated, state.room_id})

    {:reply, :ok, new_state}
  end
end
