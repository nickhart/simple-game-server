require "rails_helper"

RSpec.describe User, type: :model do
  describe "factory traits" do
    it "creates an admin user with :admin trait" do
      user = create(:user, :admin)
      expect(user.role).to eq("admin")
    end

    it "creates a user with an incremented token_version using :with_old_version" do
      user = create(:user, :with_old_version)
      expect(user.token_version).to be > 1
    end

    it "creates a user demoted from admin using :privileged_to_unprivileged" do
      user = create(:user, :privileged_to_unprivileged)
      expect(user.role).to eq("player")
    end

    it "creates a user promoted from player using :unprivileged_to_privileged" do
      user = create(:user, :unprivileged_to_privileged)
      expect(user.role).to eq("admin")
    end
  end
end
