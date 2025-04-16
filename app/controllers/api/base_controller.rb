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

    # Renders a standardized success response
    # Options hash may contain:
    #   :status - the HTTP status (default: :ok)
    #   :include - for rendering associations (if needed)
    def render_success(payload, options = {})
      render json: { data: payload }, status: options.fetch(:status, :ok), include: options[:include]
    end

    # Renders a standardized error response
    # If errors is an Array, it assigns it to key :errors; if it's a single message, it assigns it to :error.
    # Options hash may contain:
    #   :status - the HTTP status (default: :unprocessable_entity)
    def render_error(errors, options = {})
      status = options.fetch(:status, :unprocessable_entity)
      error_payload = errors.is_a?(Array) ? { errors: errors } : { error: errors }
      render json: error_payload, status: status
    end

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

      render_error("Only JSON requests are accepted", status: :not_acceptable)
    end

    def set_json_content_type
      response.headers["Content-Type"] = "application/json"
    end

    def authenticate_user!
      authenticate_or_request_with_http_token do |token, _options|
        payload = JWT.decode(token, Rails.application.credentials.secret_key_base).first
        @current_user = User.find(payload["user_id"])

        # Check if token is blacklisted
        # puts "Decoded payload: #{payload}"
        # puts "Current user: #{@current_user&.id}, token version: #{@current_user&.token_version}"

        token_record = Token.find_by(jti: payload["jti"])
        # puts "Token record: #{token_record&.inspect}"
        if token_record&.expired?
          render_error("Token has expired", status: :unauthorized)
          return false
        end

        # Check token version
        if payload["token_version"] != @current_user.token_version
          render_error("Token has been invalidated", status: :unauthorized)
          return false
        end

        # Check role matches database
        if payload["role"] != @current_user.role
          render_error("User role has changed, please log in again", status: :unauthorized)
          return false
        end

        Current.user = @current_user
        true
      rescue JWT::ExpiredSignature
        render_error("Token has expired", status: :unauthorized)
        false
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render_error("Invalid token", status: :unauthorized)
        false
      end
    end

    def authorize_admin!
      render_error("Forbidden", status: :forbidden) unless Current.user&.admin?
    end

    def current_user
      @current_user || Current.user
    end

    def render_unauthorized
      render_error("Unauthorized", status: :unauthorized)
    end
  end
end
