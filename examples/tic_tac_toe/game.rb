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
    @current_player = nil
  end

  def play
    @current_player = @client.current_player
    puts "Welcome to TicTacToe!"
    puts "You are playing as #{@current_player.name}"
    puts "Game session ID: #{@game_session.id}"

    loop do
      # Wait for our turn
      @game_session = wait_for_turn

      if @game_session.status == "finished"
        display_board
        if @game_session.state["winner"]
          puts "Player #{@game_session.state["winner"] + 1} wins!"
        else
          puts "It's a draw!"
        end
        break
      end

      display_board
      position = player_move
      result = make_move(position)
      display_board

      if result.success?
        if result.data[:game_over]
          puts result.data[:message]
          break
        end
      else
        puts result.error
      end
    end
  end

  private

  def wait_for_turn
    puts "Waiting for your turn..."

    loop do
      # Refresh the game session to get the latest state
      result = @client.get_game_session(@game_session.id)

      if result.failure?
        puts "Error refreshing game session: #{result.error}"
        sleep(2) # Wait before retrying
        next
      end

      updated_session = result.data

      if updated_session.status == "finished"
        return updated_session
      end

      if updated_session.current_player && updated_session.current_player.id == @current_player.id
        puts "It's your turn!"
        return updated_session
      end

      print "."
      sleep(2) # Check every 2 seconds
    end
  end

  def display_board
    puts "\nCurrent board:"
    # this is where we have a bug and the board is not displayed correctly
    # I think the board is nil?
    Board.new(@game_session.state["board"]).display
  end

  def player_move
    loop do
      print "Enter your move (0-8): "
      position = gets.chomp.to_i
      return position if position.between?(0, 8)

      puts "Invalid move. Please enter a number between 1 and 9."
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
    @game_session.state["board"] = @game_session.board.board

    winner = @game_session.board.winner
    if winner && winner != Board::CELL_VALUES[:empty]
      player_index = winner == Board::CELL_VALUES[:player1] ? 0 : 1
      @client.update_game_state(@game_session.id, { board: @game_session.board.board }, "finished", player_index)
      Result.success(game_over: true, message: "Player #{winner} wins!")
    elsif @game_session.board.full?
      @client.update_game_state(@game_session.id, { board: @game_session.board.board }, "finished")
      Result.success(game_over: true, message: "It's a draw!")
    else
      player_id = @game_session.players.find { |p| p.id != @current_player.id }.id
      @client.update_game_state(@game_session.id, { board: @game_session.board.board })
      Result.success(game_over: false)
    end
  end
end
