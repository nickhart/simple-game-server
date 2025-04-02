class Board
  attr_reader :board

  WINNING_COMBINATIONS = [
    [ 0, 1, 2 ], [ 3, 4, 5 ], [ 6, 7, 8 ], # Rows
    [ 0, 3, 6 ], [ 1, 4, 7 ], [ 2, 5, 8 ], # Columns
    [ 0, 4, 8 ], [ 2, 4, 6 ]             # Diagonals
  ]

  def initialize(board = nil)
    @board = if board
      # Ensure we have a 9-element array, filling with 0 (empty) if needed
      # Convert all values to integers, using 0 for nil or invalid values
      Array.new(9) { |i| (board[i].to_i rescue 0) }
    else
      Array.new(9, 0)  # 0 represents empty
    end
  end

  def display
    puts "\nCurrent board:"
    @board.each_slice(3).each_with_index do |row, i|
      row_display = row.map.with_index do |cell, j|
        position = (i * 3) + j + 1
        case cell
        when 0
          position.to_s
        when 1
          'X'
        when 2
          'O'
        end
      end.join(' | ')
      puts row_display
      puts '-' * 9 unless i == 2
    end
  end

  def make_move(position, player_index)
    return false unless position.between?(1, 9)
    return false unless @board[position - 1] == 0  # Check if position is empty (0)

    # Create a new array with the move
    new_board = @board.dup
    new_board[position - 1] = player_index + 1  # Convert 0-based index to 1-based player number
    @board = new_board
    true
  end

  def get_position(position)
    @board[position - 1]
  end

  def winner
    # Check rows
    @board.each_slice(3) do |row|
      return row[0] if row.uniq.size == 1 && row[0] != 0
    end

    # Check columns
    3.times do |col|
      column = [@board[col], @board[col + 3], @board[col + 6]]
      return column[0] if column.uniq.size == 1 && column[0] != 0
    end

    # Check diagonals
    diagonal1 = [@board[0], @board[4], @board[8]]
    return diagonal1[0] if diagonal1.uniq.size == 1 && diagonal1[0] != 0

    diagonal2 = [@board[2], @board[4], @board[6]]
    return diagonal2[0] if diagonal2.uniq.size == 1 && diagonal2[0] != 0

    nil
  end

  def full?
    @board.none? { |cell| cell == 0 }
  end

  def empty?
    @board.all? { |cell| cell == 0 }
  end

  def [](index)
    @board[index]
  end

  private

  def valid_move?(board, position, player_index)
    # Check if the position is empty (0)
    return false unless board[position - 1] == 0

    # The move is valid if the position is empty
    true
  end

  def winner?(board, player_index)
    player_number = player_index + 1  # Convert 0-based index to 1-based player number
    
    # Check rows
    board.each_slice(3) do |row|
      return true if row.all? { |cell| cell == player_number }
    end

    # Check columns
    3.times do |col|
      return true if [board[col], board[col + 3], board[col + 6]].all? { |cell| cell == player_number }
    end

    # Check diagonals
    return true if [board[0], board[4], board[8]].all? { |cell| cell == player_number }
    return true if [board[2], board[4], board[6]].all? { |cell| cell == player_number }

    false
  end
end
