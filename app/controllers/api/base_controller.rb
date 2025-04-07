module Api
  class BaseController < ApplicationController
    # Skip CSRF protection for API requests since they use token authentication
    skip_before_action :verify_authenticity_token

    # Ensure all API requests are JSON
    before_action :ensure_json_request
    before_action :authenticate_user!

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

    def authenticate_user!
      token = request.headers["Authorization"]&.split&.last
      return render_unauthorized unless token

      begin
        decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base)
        @jwt_payload = decoded_token[0]

        # Check token expiration
        if @jwt_payload["exp"] && Time.current.to_i > @jwt_payload["exp"]
          return render json: { error: "Token has expired" }, status: :unauthorized
        end

        # Find user and verify role matches token
        @current_user = User.find(@jwt_payload["sub"])
        if @current_user.role != @jwt_payload["role"]
          return render json: { error: "User role mismatch" }, status: :unauthorized
        end

        Current.user = @current_user
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render_unauthorized
      end
    end

    attr_reader :current_user, :jwt_payload

    def render_unauthorized
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
