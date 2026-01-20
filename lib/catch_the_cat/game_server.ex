defmodule CatchTheCat.GameServer do
  @moduledoc """
  GenServer для управления состоянием игры.
  Хранит игры в памяти и обрабатывает ходы.
  """
  use GenServer

  # Клиентский API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc "Создать новую игру"
  def create_game(grid_size \\ 9) do
    GenServer.call(__MODULE__, {:create_game, grid_size})
  end

  @doc "Сделать ход"
  def make_move(game_id, x, y) do
    GenServer.call(__MODULE__, {:make_move, game_id, x, y})
  end

  @doc "Получить состояние игры"
  def get_game(game_id) do
    GenServer.call(__MODULE__, {:get_game, game_id})
  end

  # Серверные коллбэки
  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:create_game, grid_size}, _from, games) do
    game = CatchTheCat.Game.new(grid_size)
    games = Map.put(games, game.id, game)
    {:reply, {:ok, game}, games}
  end

  @impl true
  def handle_call({:make_move, game_id, x, y}, _from, games) do
    case Map.get(games, game_id) do
      nil ->
        {:reply, {:error, :game_not_found}, games}

      game ->
        case CatchTheCat.Game.player_move(game, x, y) do
          {:ok, updated_game} ->
            games = Map.put(games, game_id, updated_game)
            {:reply, {:ok, updated_game}, games}

          {:error, reason} ->
            {:reply, {:error, reason}, games}
        end
    end
  end

  @impl true
  def handle_call({:get_game, game_id}, _from, games) do
    case Map.get(games, game_id) do
      nil -> {:reply, {:error, :game_not_found}, games}
      game -> {:reply, {:ok, game}, games}
    end
  end
end
