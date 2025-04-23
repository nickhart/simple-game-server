require "rails_helper"

RSpec.describe User, type: :model do
  describe "factory traits" do
    it "has a default token_version of 1" do
      user = create(:user)
      expect(user.token_version).to eq(1)
    end

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

  describe "Player association" do
    it "can exist without a player" do
      user = create(:user)
      expect(user.player).to be_nil
    end

    it "can be associated with a player after creation" do
      user = create(:user)
      player = create(:player, user: user)
      expect(user.reload.player).to eq(player)
    end
  end

  describe "#make_admin!" do
    it "sets the role to admin and saves the user" do
        user = create(:user, role: "player")
        user.make_admin!
        expect(user.reload.role).to eq("admin")
    end
  end

  describe "#remove_admin!" do
    it "sets the role to player and saves the user" do
        user = create(:user, role: "admin")
        user.remove_admin!
        expect(user.reload.role).to eq("player")
    end
  end
end
