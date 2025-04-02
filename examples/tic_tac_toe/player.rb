class Player
  attr_reader :id, :name, :user_id

  def initialize(data)
    @id = data["id"]
    @name = data["name"]
    @user_id = data["user_id"]
  end

  def to_s
    "#{name} (ID: #{id})"
  end
end 