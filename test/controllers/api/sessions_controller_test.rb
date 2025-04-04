require "test_helper"

module Api
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      @headers = {
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    end

    test "should create session with valid credentials" do
      post api_sessions_path,
           params: {
             email: @user.email,
             password: "password123"
           }.to_json,
           headers: @headers

      assert_response :success
      assert_not_nil JSON.parse(response.body)["token"]
    end

    test "should not create session with invalid password" do
      post api_sessions_path,
           params: {
             email: @user.email,
             password: "wrongpassword"
           }.to_json,
           headers: @headers

      assert_response :unauthorized
      assert_includes JSON.parse(response.body)["error"], "Invalid email or password"
    end

    test "should not create session with invalid email" do
      post api_sessions_path,
           params: {
             email: "nonexistent@example.com",
             password: "password123"
           }.to_json,
           headers: @headers

      assert_response :unauthorized
      assert_includes JSON.parse(response.body)["error"], "Invalid email or password"
    end
  end
end
