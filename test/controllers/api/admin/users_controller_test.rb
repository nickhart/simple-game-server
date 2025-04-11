require "test_helper"

module Api
  module Admin
    class UsersControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin = users(:admin)
        @player = users(:player)
        @other_player = users(:other_player)
      end

      test "should not allow unauthenticated access" do
        get api_admin_users_url
        assert_response :unauthorized

        get api_admin_user_url(@player)
        assert_response :unauthorized

        patch api_admin_user_url(@player), params: { user: { email: "new@example.com" } }
        assert_response :unauthorized

        post make_admin_api_admin_user_url(@player)
        assert_response :unauthorized

        post remove_admin_api_admin_user_url(@player)
        assert_response :unauthorized
      end

      test "should not allow non-admin access" do
        get api_admin_users_url, headers: auth_headers(@player)
        assert_response :forbidden

        get api_admin_user_url(@player), headers: auth_headers(@player)
        assert_response :forbidden

        patch api_admin_user_url(@player),
              params: { user: { email: "new@example.com" } },
              headers: auth_headers(@player)
        assert_response :forbidden

        post make_admin_api_admin_user_url(@player), headers: auth_headers(@player)
        assert_response :forbidden

        post remove_admin_api_admin_user_url(@player), headers: auth_headers(@player)
        assert_response :forbidden
      end

      test "should list all users" do
        get api_admin_users_url, headers: auth_headers(@admin)
        assert_response :success

        response_body = JSON.parse(response.body)
        assert_equal User.count, response_body["data"].length
        assert_equal @player.email, response_body["data"].find { |u| u["id"] == @player.id }["email"]
      end

      test "should paginate users list" do
        get api_admin_users_url, params: { page: 1, per_page: 1 }, headers: auth_headers(@admin)
        assert_response :success

        response_body = JSON.parse(response.body)
        assert_equal 1, response_body["data"].length
      end

      test "should search users" do
        get api_admin_users_url, params: { q: @player.email }, headers: auth_headers(@admin)
        assert_response :success

        response_body = JSON.parse(response.body)
        assert_equal 1, response_body["data"].length
        assert_equal @player.email, response_body["data"].first["email"]
      end

      test "should show user" do
        get api_admin_user_url(@player), headers: auth_headers(@admin)
        assert_response :success

        response_body = JSON.parse(response.body)
        assert_equal @player.email, response_body["data"]["email"]
      end

      test "should return not found for non-existent user" do
        get api_admin_user_url(id: 999_999), headers: auth_headers(@admin)
        assert_response :not_found
      end

      test "should update user" do
        new_email = "updated@example.com"
        patch api_admin_user_url(@player),
              params: { user: { email: new_email } },
              headers: auth_headers(@admin)
        assert_response :success

        @player.reload
        assert_equal new_email, @player.email
      end

      test "should not update user with invalid data" do
        patch api_admin_user_url(@player),
              params: { user: { email: "" } },
              headers: auth_headers(@admin)
        assert_response :unprocessable_entity
      end

      test "should not update user with invalid role" do
        patch api_admin_user_url(@player),
              params: { user: { role: "invalid_role" } },
              headers: auth_headers(@admin)
        assert_response :unprocessable_entity
      end

      test "should make user admin" do
        assert_changes -> { @player.reload.admin? }, from: false, to: true do
          post make_admin_api_admin_user_url(@player), headers: auth_headers(@admin)
        end
        assert_response :success
      end

      test "should handle already admin user" do
        post make_admin_api_admin_user_url(@admin), headers: auth_headers(@admin)
        assert_response :unprocessable_entity
      end

      test "should handle non-existent user in make_admin" do
        post make_admin_api_admin_user_url(id: 999_999), headers: auth_headers(@admin)
        assert_response :not_found
      end

      test "should remove admin role" do
        @player.update!(role: "admin")

        assert_changes -> { @player.reload.admin? }, from: true, to: false do
          post remove_admin_api_admin_user_url(@player), headers: auth_headers(@admin)
        end
        assert_response :success
      end

      test "should handle non-admin user when removing admin role" do
        post remove_admin_api_admin_user_url(@player), headers: auth_headers(@admin)
        assert_response :unprocessable_entity
      end

      test "should handle non-existent user in remove_admin" do
        post remove_admin_api_admin_user_url(id: 999_999), headers: auth_headers(@admin)
        assert_response :not_found
      end
    end
  end
end
