defmodule CatchTheCatWeb.GameController do
  use CatchTheCatWeb, :controller

  @doc "Главная страница игры"
  def index(conn, _params) do
    # Создаем новую игру при заходе на страницу
    {:ok, game} = CatchTheCat.GameServer.create_game(9)

    render(conn, :index,
      game_id: game.id,
      grid_size: game.grid_size,
      cat_position: game.cat_position,
      blocks: game.blocks,
      score: game.score,
      moves: game.moves,
      game_over: game.game_over
    )
  end

  @doc "API: Сделать ход"
  def move(conn, %{"game_id" => game_id, "x" => x, "y" => y}) do
    {x_int, _} = Integer.parse(x)
    {y_int, _} = Integer.parse(y)

    case CatchTheCat.GameServer.make_move(game_id, x_int, y_int) do
      {:ok, game} ->
        json(conn, %{
          success: true,
          cat_position: Tuple.to_list(game.cat_position),
          blocks: Enum.map(game.blocks, &Tuple.to_list/1),
          score: game.score,
          moves: game.moves,
          game_over: game.game_over,
          message: game_message(game)
        })

      {:error, reason} ->
        json(conn, %{
          success: false,
          error: human_error(reason)
        })
    end
  end

  defp game_message(game) do
    cond do
      game.game_over and cat_trapped?(game.cat_position, game.blocks, game.grid_size) ->
        "🎉 Вы поймали кота! Счет: #{game.score}"
      game.game_over ->
        "😿 Кот убежал! Попробуйте еще раз"
      true ->
        "Ход #{game.moves}. Счет: #{game.score}"
    end
  end

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

  defp human_error(:game_not_found), do: "Игра не найдена"
  defp human_error(:game_over), do: "Игра завершена"
  defp human_error(:out_of_bounds), do: "Ход за пределы поля"
  defp human_error(:cat_position), do: "Нельзя ставить блок на кота"
  defp human_error(:block_exists), do: "Здесь уже есть блок"
  defp human_error(_), do: "Неизвестная ошибка"
end
