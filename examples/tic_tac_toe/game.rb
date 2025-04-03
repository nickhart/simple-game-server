require_relative "client"
require_relative "board"
require_relative "result"
require_relative "game_session"
require_relative "player"

class Game
  attr_reader :client, :game_session, :board, :current_player

  def initialize(client, game_session)
    @client = client
    @game_session = game_session
    @board = Board.new
    @current_player = nil
  end

  def play
    @current_player = @client.get_current_player
    puts "Welcome to TicTacToe!"
    puts "You are playing as #{@current_player.name}"
    puts "Game session ID: #{@game_session.id}"

    loop do
      display_board
      position = get_player_move
      result = make_move(position)

      if result.success?
        if result.data[:game_over]
          display_board
          puts result.data[:message]
          break
        end
      else
        puts result.error
      end
    end
  end

  private

  def display_board
    puts "\nCurrent board:"
    @board.display
  end

  def get_player_move
    loop do
      print "Enter your move (1-9): "
      position = gets.chomp.to_i
      return position if position.between?(1, 9)
      puts "Invalid move. Please enter a number between 1 and 9."
    end
  end

  def make_move(position)
    return Result.failure("Invalid position") unless position.between?(1, 9)
    return Result.failure("Position already taken") unless @board.valid_move?(position)

    @board.make_move(position, @current_player.id)
    @client.update_game_state(@game_session.id, { board: @board.board })

    if @board.winner?
      Result.success(game_over: true, message: "Player #{@current_player.name} wins!")
    elsif @board.draw?
      Result.success(game_over: true, message: "It's a draw!")
    else
      Result.success(game_over: false)
    end
  end
end
