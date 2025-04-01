class Board
  WINNING_COMBINATIONS = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], # Rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], # Columns
    [0, 4, 8], [2, 4, 6]             # Diagonals
  ]

  def initialize
    @board = Array.new(9) { nil }
  end

  def display
    puts "\n"
    @board.each_slice(3).with_index do |row, i|
      puts " #{row.map { |cell| cell || (i * 3 + row.index(cell) + 1) }.join(' | ')} "
      puts "-----------" unless i == 2
    end
    puts "\n"
  end

  def make_move(position, player)
    return false if position < 1 || position > 9
    return false if @board[position - 1]

    @board[position - 1] = player
    true
  end

  def winner
    WINNING_COMBINATIONS.each do |combo|
      values = combo.map { |i| @board[i] }
      return values[0] if values.uniq.size == 1 && values[0]
    end
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
    board.instance_variable_set(:@board, string.split(',').map { |c| c == '' ? nil : c })
    board
  end
end 