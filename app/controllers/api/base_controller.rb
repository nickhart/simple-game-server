module Api
  class BaseController < ApplicationController
    include ActionController::HttpAuthentication::Token::ControllerMethods

    # Skip CSRF protection for API requests since they use token authentication
    skip_before_action :verify_authenticity_token

    # Ensure all API requests and responses are JSON
    before_action :ensure_json_request
    before_action :authenticate_user!
    after_action :set_json_content_type

    private

    def ensure_json_request
      # Accept if content type is application/json or if the request format is json
      return if request.content_type == "application/json" || request.format.json?

      # Also accept if the request body is JSON
      begin
        JSON.parse(request.body.read)
        request.body.rewind
        return
      rescue JSON::ParserError
        # Not JSON, continue to error
      end

      render json: { error: "Only JSON requests are accepted" }, status: :not_acceptable
    end

    def set_json_content_type
      response.headers["Content-Type"] = "application/json"
    end

    def authenticate_user!
      authenticate_or_request_with_http_token do |token, _options|
        payload = JWT.decode(token, Rails.application.credentials.secret_key_base).first
        @current_user = User.find(payload["user_id"])

        if payload["token_version"] != @current_user.token_version
          render json: { error: "Token has been invalidated" }, status: :unauthorized
          return false
        end

        Current.user = @current_user
        true
      rescue JWT::ExpiredSignature
        render json: { error: "Token has expired" }, status: :unauthorized
        false
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render json: { error: "Invalid token" }, status: :unauthorized
        false
      end
    end

    def current_user
      @current_user || Current.user
    end

    def render_unauthorized
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
