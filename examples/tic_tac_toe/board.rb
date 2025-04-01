class Board
  attr_reader :board

  WINNING_COMBINATIONS = [
    [ 0, 1, 2 ], [ 3, 4, 5 ], [ 6, 7, 8 ], # Rows
    [ 0, 3, 6 ], [ 1, 4, 7 ], [ 2, 5, 8 ], # Columns
    [ 0, 4, 8 ], [ 2, 4, 6 ]             # Diagonals
  ]

  def initialize(initial_state = nil)
    @board = if initial_state
      initial_state.map { |cell| cell.nil? ? nil : cell.to_i }
    else
      Array.new(9) { nil }
    end
  end

  def display
    puts "\nCurrent board state:"
    @board.each_slice(3).each_with_index do |row, i|
      row_display = row.map.with_index do |cell, j|
        position = (i * 3) + j + 1
        if cell.nil?
          position.to_s
        else
          cell == 0 ? 'X' : 'O'
        end
      end.join(' | ')
      puts row_display
      puts '-----------' unless i == 2
    end
    puts
  end

  def make_move(position, player)
    return false if position < 1 || position > 9
    return false if @board[position - 1]

    @board[position - 1] = player
    true
  end

  def winner
    # Check rows
    @board.each_slice(3) do |row|
      return row[0] if row.uniq.size == 1 && !row[0].nil?
    end

    # Check columns
    3.times do |col|
      column = [@board[col], @board[col + 3], @board[col + 6]]
      return column[0] if column.uniq.size == 1 && !column[0].nil?
    end

    # Check diagonals
    diagonal1 = [@board[0], @board[4], @board[8]]
    return diagonal1[0] if diagonal1.uniq.size == 1 && !diagonal1[0].nil?

    diagonal2 = [@board[2], @board[4], @board[6]]
    return diagonal2[0] if diagonal2.uniq.size == 1 && !diagonal2[0].nil?

    nil
  end

  def full?
    @board.none?(&:nil?)
  end

  def empty?
    @board.all?(&:nil?)
  end

  def to_s
    @board.join(',')
  end

  def self.from_s(string)
    board = new
    board.instance_variable_set(:@board, string.split(',').map { |cell| cell == 'nil' ? nil : cell.to_i })
    board
  end

  def [](index)
    @board[index]
  end

  def []=(index, value)
    @board[index] = value
  end
end
