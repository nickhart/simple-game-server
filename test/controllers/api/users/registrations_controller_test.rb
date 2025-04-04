require "test_helper"

module Api
  module Users
    class RegistrationsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @headers = {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }
      end

      test "should register new user with valid data" do
        assert_difference("User.count") do
          post "/api/users",
               params: {
                 user: {
                   email: "newuser@example.com",
                   password: "password123",
                   password_confirmation: "password123"
                 }
               }.to_json,
               headers: @headers
        end

        assert_response :created
        assert_not_nil JSON.parse(response.body)["token"]
        assert User.find_by(email: "newuser@example.com")
      end

      test "should not register user with invalid email" do
        assert_no_difference("User.count") do
          post "/api/users",
               params: {
                 user: {
                   email: "invalid-email",
                   password: "password123",
                   password_confirmation: "password123"
                 }
               }.to_json,
               headers: @headers
        end

        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"]["email"], "is invalid"
      end

      test "should not register user with mismatched passwords" do
        assert_no_difference("User.count") do
          post "/api/users",
               params: {
                 user: {
                   email: "newuser@example.com",
                   password: "password123",
                   password_confirmation: "different123"
                 }
               }.to_json,
               headers: @headers
        end

        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"]["password_confirmation"], "doesn't match Password"
      end

      test "should not register user with duplicate email" do
        existing_user = users(:one)

        assert_no_difference("User.count") do
          post "/api/users",
               params: {
                 user: {
                   email: existing_user.email,
                   password: "password123",
                   password_confirmation: "password123"
                 }
               }.to_json,
               headers: @headers
        end

        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"]["email"], "has already been taken"
      end

      test "should not register user with short password" do
        assert_no_difference("User.count") do
          post "/api/users",
               params: {
                 user: {
                   email: "newuser@example.com",
                   password: "short",
                   password_confirmation: "short"
                 }
               }.to_json,
               headers: @headers
        end

        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"]["password"], "is too short"
      end
    end
  end
end
