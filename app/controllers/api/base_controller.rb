module Api
  class BaseController < ApplicationController
    # Skip CSRF protection for all API requests
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
        user_id = decoded_token[0]["sub"]
        Current.user = User.find(user_id)
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render_unauthorized
      end
    end

    def render_unauthorized
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
