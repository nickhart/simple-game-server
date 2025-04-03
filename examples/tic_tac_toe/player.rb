class Player
  attr_reader :id, :name

  def initialize(attributes)
    @id = attributes["id"]
    @name = attributes["name"]
  end

  def to_s
    name
  end
end 