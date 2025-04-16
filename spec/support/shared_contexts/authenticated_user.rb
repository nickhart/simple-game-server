RSpec.shared_context "authenticated_user" do
  let(:user) { create(:user) }
  let(:token) { create(:token, user: user, token_type: "access", expires_at: 1.hour.from_now) }

  before do
    request.headers["Authorization"] = "Bearer #{token.jti}"
  end
end

RSpec.shared_context "authenticated as admin" do
  let!(:admin_user) { create(:user, :admin) }
  
  before do
    authorize_as(admin_user)
  end
end
  
RSpec.shared_context "authenticated as player" do
  let!(:player_user) { create(:user) }

  before do
    authorize_as(player_user)
  end
end