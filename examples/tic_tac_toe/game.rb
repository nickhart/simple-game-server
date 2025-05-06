require_relative "board"
require_relative "../lib/result"
require_relative "../lib/services"
require_relative "game_session"
require_relative "player"

class Game
  attr_reader :game_session, :current_player

  def initialize(game_session)
    @game_session = game_session
  end

  def play
    result = Services.players.me
    return puts result.error unless result.success?
    @current_player = Player.new(result.data)
    
    puts "Welcome to Tic-Tac-Toe!"
    puts "You are player #{@game_session.players.find_index { |p| p.id == @current_player.id } + 1}"
    puts "Game ID: #{@game_session.id}"

    loop do
      display_board
      break if game_over?

      if @game_session.current_player.id == @current_player.id
        res = player_move
        if res.success?
          # Inspect the payload your handlers put into data
          if res.data[:game_over]
            # Optional: print the message they returned
            puts res.data[:message] if res.data[:message]
            break
          end
        else
          # Handle the validation or API error
          puts res.error
        end
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
      result = Services.sessions.get(@game_session.game_id, @game_session.id)
      if result.failure?
        puts result.error
        next
      end
      @game_session = GameSession.new(result.data)
      break if @game_session.current_player.id == @current_player.id || game_over?
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
    result = @game_session.update_state(state: { board: @game_session.board.board }, status: :finished, winner: player_index)
    return result unless result.success?
    Result.success(game_over: true, message: "Player #{winner} wins!")
  end

  def handle_draw
    result = @game_session.update_state(state: { board: @game_session.board.board }, status: :finished)
    return result unless result.success?
    Result.success(game_over: true, message: "It's a draw!")
  end

  def handle_next_turn
    # current_index = @game_session.players.find_index { |p| p.id == @current_player.id }
    # next_index = (current_index + 1) % @game_session.players.size
    
    result = @game_session.update_state(state: { board: @game_session.board.board })
    return result unless result.success?
    Result.success(game_over: false)
  end
end
