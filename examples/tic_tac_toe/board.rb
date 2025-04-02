class Board
  WINNING_COMBINATIONS = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], # Rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], # Columns
    [0, 4, 8], [2, 4, 6] # Diagonals
  ].freeze

  attr_reader :board

  def [](index)
    board[index]
  end

  def initialize(board = nil)
    @board = board ? initialize_board(board) : Array.new(9, 0)
  end

  def display
    @board.each_slice(3).with_index do |row, i|
      display_row(row)
      puts "-" * 9 unless i == 2
    end
  end

  def valid_move?(position)
    return false unless position.between?(1, 9)

    return false unless @board[position - 1].zero? # Check if position is empty (0)

    true
  end

  def make_move(position, player_index)
    return false unless valid_move?(position)

    new_board = @board.dup
    new_board[position - 1] = player_index + 1 # Convert 0-based index to 1-based player number
    @board = new_board
    true
  end

  def winner
    WINNING_COMBINATIONS.each do |combo|
      values = combo.map { |i| @board[i] }
      next if values.any?(&:zero?)
      return values.first if values.uniq.size == 1
    end
    nil
  end

  def full?
    @board.none?(&:zero?)
  end

  def empty?
    @board.all?(&:zero?)
  end

  def valid_move_for_board?(board, position, _player_index)
    return false unless position.between?(1, 9)

    return false unless board[position - 1].zero?

    true
  end

  def winner?(board, player_index)
    player_number = player_index + 1 # Convert 0-based index to 1-based player number
    check_winning_combinations(board, player_number)
  end

  private

  def initialize_board(board)
    Array.new(9) do |i|
      board[i].to_i
    rescue StandardError
      0
    end
  end

  def display_row(row)
    symbols = { 1 => "X", 2 => "O", 0 => " " }
    puts row.map { |cell| symbols[cell] }.join(" | ")
  end

  def check_winning_combinations(board, player_number)
    check_rows(board, player_number) ||
      check_columns(board, player_number) ||
      check_diagonals(board, player_number)
  end

  def check_rows(board, player_number)
    board.each_slice(3).any? { |row| row.all?(player_number) }
  end

  def check_columns(board, player_number)
    (0..2).any? do |col|
      column = [board[col], board[col + 3], board[col + 6]]
      column.all?(player_number)
    end
  end

  def check_diagonals(board, player_number)
    diagonal1 = [board[0], board[4], board[8]]
    diagonal2 = [board[2], board[4], board[6]]
    diagonal1.all?(player_number) || diagonal2.all?(player_number)
  end
end
