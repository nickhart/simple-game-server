require_relative "client"
require_relative "board"
require_relative "result"
require_relative "game_session"
require_relative "player"

class Game
  attr_reader :client, :game_session, :current_player

  def initialize(client, game_session)
    @client = client
    @game_session = game_session
  end

  def play
    @current_player = @client.current_player
    puts "Welcome to Tic-Tac-Toe!"
    puts "You are player #{@game_session.players.find_index { |p| p.id == @current_player.id } + 1}"
    puts "Game ID: #{@game_session.id}"

    loop do
      display_board
      break if game_over?

      if @game_session.current_player_id == @current_player.id
        result = player_move
        break if result.game_over?
      else
        wait_for_turn
      end
    end
  end

  private

  def game_over?
    @game_session.status == :finished
  end

  def wait_for_turn
    puts "Waiting for your turn..."
    loop do
      sleep(1)
      @game_session = @client.get_game_session(@game_session.id)
      break if @game_session.current_player_id == @current_player.id || game_over?
    end
  end

  def display_board
    puts "\nCurrent board:"
    @game_session.board.display
  end

  def player_move
    loop do
      print "Enter your move (0-8): "
      position = gets.chomp.to_i
      result = make_move(position)
      return result if result.success?

      puts result.error
    end
  end

  def player_cell_value
    player_index = @game_session.players.find_index { |p| p.id == @current_player.id }
    case player_index
    when 0
      Board::CELL_VALUES[:player1]
    when 1
      Board::CELL_VALUES[:player2]
    else
      raise "Invalid player index: #{player_index}"
    end
  end

  def make_move(position)
    return Result.failure("Invalid position") unless position.between?(0, 8)
    return Result.failure("Position already taken") unless @game_session.board.valid_move?(position)

    cell_value = player_cell_value
    @game_session.board.make_move(position, cell_value)
    update_game_state
    check_game_result
  end

  def update_game_state
    @game_session.state["board"] = @game_session.board.board
  end

  def check_game_result
    winner = @game_session.board.winner
    if winner
      handle_winner(winner)
    elsif @game_session.board.full?
      handle_draw
    else
      handle_next_turn
    end
  end

  def handle_winner(winner)
    player_index = winner == Board::CELL_VALUES[:player1] ? 0 : 1
    @client.update_game_state(@game_session.id, { board: @game_session.board.board }, :finished, player_index)
    Result.success(game_over: true, message: "Player #{winner} wins!")
  end

  def handle_draw
    @client.update_game_state(@game_session.id, { board: @game_session.board.board }, :finished)
    Result.success(game_over: true, message: "It's a draw!")
  end

  def handle_next_turn
    @game_session.players.find { |p| p.id != @current_player.id }.id
    @client.update_game_state(@game_session.id, { board: @game_session.board.board })
    Result.success(game_over: false)
  end
end
