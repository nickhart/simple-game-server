require "rails_helper"

RSpec.describe "DatabaseCleaner" do
  it "creates a player in one example" do
    create(:player)
    expect(Player.count).to eq(1)
  end

  it "resets primary key sequences" do
    create(:player) # should not fail
  end

  it "cleans the database before the next example" do
    expect(Player.count).to eq(0)
  end
end
