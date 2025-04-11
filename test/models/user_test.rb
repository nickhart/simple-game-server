require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    duplicate_user = @user.dup
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "should require valid email format" do
    @user.email = "invalid_email"
    assert_not @user.valid?
    assert_includes @user.errors[:email], "is invalid"
  end

  test "should require password with minimum length" do
    @user.password = "short"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "should require role" do
    @user.role = nil
    assert_not @user.valid?
    assert_includes @user.errors[:role], "can't be blank"
  end

  test "should require valid role" do
    @user.role = "invalid_role"
    assert_not @user.valid?
    assert_includes @user.errors[:role], "is not included in the list"
  end

  test "should initialize token version on create" do
    new_user = User.new(
      email: "new@example.com",
      password: "password123",
      role: "player"
    )
    assert_nil new_user.token_version
    new_user.save!
    assert_equal 1, new_user.token_version
  end

  test "should increment token version" do
    initial_version = @user.token_version
    @user.invalidate_token!
    assert_equal initial_version + 1, @user.token_version
  end

  test "should identify admin users" do
    admin = users(:admin)
    assert admin.admin?
    assert_not admin.player?
  end

  test "should identify player users" do
    player = users(:player)
    assert player.player?
    assert_not player.admin?
  end

  test "should handle role changes" do
    @user.role = "admin"
    assert @user.admin?
    assert_not @user.player?

    @user.role = "player"
    assert @user.player?
    assert_not @user.admin?
  end
end
