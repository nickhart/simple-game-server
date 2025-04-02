class Board
  CELL_VALUES = {
    empty: 0,
    player1: 1,
    player2: 2
  }.freeze

  WINNING_COMBINATIONS = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], # Rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], # Columns
    [0, 4, 8], [2, 4, 6] # Diagonals
  ].freeze

  attr_reader :board

  def initialize(board_state = nil)
    @board = board_state || Array.new(9, CELL_VALUES[:empty])
  end

  def make_move(position, player_value)
    return false unless valid_move?(position)
    @board[position] = player_value
    true
  end

  def valid_move?(position)
    position.between?(0, 8) && @board[position] == CELL_VALUES[:empty]
  end

  def winner
    WINNING_COMBINATIONS.each do |combo|
      values = combo.map { |i| @board[i] }
      return values[0] if values.uniq.length == 1 && values[0] != CELL_VALUES[:empty]
    end
    nil
  end

  def full?
    !@board.include?(CELL_VALUES[:empty])
  end

  def display
    puts "\n"
    index = 0
    @board.each_slice(3) do |row|
      puts row.map { |cell| index += 1; cell_to_symbol(cell, index)   }.join(" | ")
      if index < 7
        puts "---------"
      end
      
    end
    puts "\n"
  end

  private

  def cell_to_symbol(cell, index)
    case cell
    when CELL_VALUES[:empty]
      index.to_s
    when CELL_VALUES[:player1]
      "X"
    when CELL_VALUES[:player2]
      "O"
    end
  end
end
