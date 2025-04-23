module FactoryHelpers
  def create_user_with_player!
    user = create(:user)
    user.reload # 🔍 ensure we pull any after_create side effects

    player = create(:player, user: user)
    player.reload

    puts "🧪 Created player ID: #{player.id}, user_id: #{user.id}, user persisted? #{user.persisted?}"
    raise "❌ User not persisted!" unless user.persisted?
    raise "❌ Player not persisted!" unless player.persisted?
    raise "❌ Player id was nil!" if player.id.nil?

    [user, player]
  end
end

RSpec.configure do |config|
  config.include FactoryHelpers
end
