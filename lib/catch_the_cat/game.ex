defmodule CatchTheCat.Game do
  @moduledoc """
  Логика игры "Поймай кота"
  """

  alias __MODULE__

  defstruct [
    :id,
    :grid_size,
    :cat_position,
    :blocks,
    :score,
    :moves,
    :game_over,
    :player_id
  ]

  @type t :: %Game{
    id: String.t(),
    grid_size: integer(),
    cat_position: {integer(), integer()},
    blocks: MapSet.t(),
    score: integer(),
    moves: integer(),
    game_over: boolean(),
    player_id: String.t() | nil
  }

  @doc """
  Создание новой игры

  ## Параметры:
  - grid_size: размер поля (по умолчанию 9)
  - blocks_count: количество случайных блоков (по умолчанию 15, 0 для пустого поля)
  """
  def new(grid_size \\ 9, blocks_count \\ 15) do
    mid = div(grid_size, 2)

    # Генерируем случайные блоки (исключаем позицию кота)
    random_blocks = generate_random_blocks(grid_size, blocks_count, {mid, mid})

    %Game{
      id: generate_id(),
      grid_size: grid_size,
      cat_position: {mid, mid},
      blocks: random_blocks,
      score: 0,
      moves: 0,
      game_over: false,
      player_id: nil
    }
  end

  @doc "Ход игрока - установка блока"
  def player_move(game, x, y) when is_integer(x) and is_integer(y) do
    cond do
      game.game_over ->
        {:error, :game_over}

      x < 0 or x >= game.grid_size or y < 0 or y >= game.grid_size ->
        {:error, :out_of_bounds}

      {x, y} == game.cat_position ->
        {:error, :cat_position}

      MapSet.member?(game.blocks, {x, y}) ->
        {:error, :block_exists}

      true ->
        # Добавляем блок
        new_blocks = MapSet.put(game.blocks, {x, y})

        # Кот делает ход
        {new_cat, cat_moved?} = cat_ai(game.cat_position, new_blocks, game.grid_size)

        # Проверяем состояние игры
        escaped? = cat_escaped?(new_cat, game.grid_size)
        trapped? = cat_trapped?(new_cat, new_blocks, game.grid_size)
        game_over? = escaped? or trapped?

        # Считаем очки
        score_change = cond do
          trapped? -> 100  # Поймали кота
          escaped? -> -50  # Кот убежал
          cat_moved? -> -5 # Кот переместился
          true -> -10      # Кот не может двигаться
        end

        new_game = %{game |
          cat_position: new_cat,
          blocks: new_blocks,
          score: game.score + score_change,
          moves: game.moves + 1,
          game_over: game_over?
        }

        {:ok, new_game}
    end
  end

  # AI кота - умное движение к краю
  defp cat_ai(cat_pos, blocks, grid_size) do
    {cx, cy} = cat_pos

    # Все возможные ходы кота (8 направлений)
    directions = [
      {0, 1}, {0, -1}, {1, 0}, {-1, 0},    # ортогональные
      {1, 1}, {1, -1}, {-1, 1}, {-1, -1}  # диагональные
    ]

    valid_moves = Enum.filter(directions, fn {dx, dy} ->
      nx = cx + dx
      ny = cy + dy
      valid_position?({nx, ny}, blocks, grid_size)
    end)

    if Enum.empty?(valid_moves) do
      {cat_pos, false}  # Кот не может двигаться
    else
      # Выбираем ход, который максимально приближает к краю
      best_move = Enum.max_by(valid_moves, fn {dx, dy} ->
        nx = cx + dx
        ny = cy + dy
        # Приоритет: чем ближе к краю, тем лучше
        distance_to_edge =
          nx
          |> min(ny)
          |> min(grid_size - nx - 1)
          |> min(grid_size - ny - 1)
        -distance_to_edge  # Инвертируем, чтобы минимум стал максимумом
      end)

      new_pos = {cx + elem(best_move, 0), cy + elem(best_move, 1)}
      {new_pos, true}
    end
  end

  # Проверка - кот сбежал?
  defp cat_escaped?({x, y}, grid_size) do
    x == 0 or x == grid_size - 1 or y == 0 or y == grid_size - 1
  end

  # Проверка - кот в ловушке?
  defp cat_trapped?(cat_pos, blocks, grid_size) do
    {cx, cy} = cat_pos

    directions = [
      {0, 1}, {0, -1}, {1, 0}, {-1, 0},
      {1, 1}, {1, -1}, {-1, 1}, {-1, -1}
    ]

    Enum.all?(directions, fn {dx, dy} ->
      nx = cx + dx
      ny = cy + dy
      not valid_position?({nx, ny}, blocks, grid_size)
    end)
  end

  defp valid_position?({x, y}, blocks, grid_size) do
    x >= 0 and x < grid_size and
    y >= 0 and y < grid_size and
    not MapSet.member?(blocks, {x, y})
  end

  # Генерация случайных блоков
  defp generate_random_blocks(grid_size, count, exclude_position) when count > 0 do
    # Создаем список всех возможных клеток
    all_positions =
      for x <- 0..(grid_size-1), y <- 0..(grid_size-1), do: {x, y}

    # Исключаем позицию кота
    available_positions = Enum.reject(all_positions, &(&1 == exclude_position))

    # Берем случайные клетки
    available_positions
    |> Enum.take_random(count)
    |> MapSet.new()
  end

  defp generate_random_blocks(_grid_size, 0, _exclude_position) do
    MapSet.new()
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8)
    |> Base.encode64()
    |> String.replace(~r/[+\/=]/, "")
    |> String.slice(0, 8)
  end
end
