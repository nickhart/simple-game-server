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
    #
    # @param payload [Object] the data to render
    # @param options [Hash] optional rendering options
    # @option options [Symbol] :status the HTTP status (default: :ok)
    # @option options [Array, Hash] :include associations to include in the response
    def render_success(payload, options = {})
      render json: { data: payload }, status: options.fetch(:status, :ok), include: options[:include]
    end

    # Renders a standardized created response
    #
    # @param payload [Object] the data to render
    # @param options [Hash] optional rendering options
    # @option options [Array, Hash] :include associations to include in the response
    def render_created(payload, options = {})
      render json: { data: payload }, status: :created, include: options[:include]
    end

    # Renders a standardized no content response
    def render_no_content
      head :no_content
    end

    # Renders a standardized error response
    #
    # @param errors [Array, String] error messages or a single error message
    # @param options [Hash] optional rendering options
    # @option options [Symbol] :status the HTTP status (default: :unprocessable_entity)
    def render_error(errors, options = {})
      status = options.fetch(:status, :unprocessable_entity)
      error_payload = errors.is_a?(Array) ? { errors: errors } : { error: errors }
      render json: error_payload, status: status
    end

    # Renders a standardized unprocessable entity response
    #
    # @param errors [Array, String] error messages or a single error message
    def render_unprocessable_entity(errors)
      render_error(errors, status: :unprocessable_entity)
    end

    # Renders a standardized not found response
    #
    # @param resource [String] the name of the resource not found (default: "Resource")
    # @param message [String, nil] optional custom error message
    def render_not_found(resource = "Resource", message = nil)
      render_error(message || "#{resource} not found", status: :not_found)
    end

    # Renders a standardized unauthorized response
    #
    # @param message [String] the error message (default: "Unauthorized")
    def render_unauthorized(message = "Unauthorized")
      render_error(message, status: :unauthorized)
    end

    # Renders a standardized forbidden response
    #
    # @param message [String] the error message (default: "Forbidden")
    def render_forbidden(message = "Forbidden")
      render_error(message, status: :forbidden)
    end

    # Renders a standardized internal server error response
    #
    # @param message [String] the error message (default: "Internal server error")
    def render_internal_error(message = "Internal server error")
      render_error(message, status: :internal_server_error)
    end

    def render_bad_request(message = "Bad request")
      render_error(message, status: :bad_request)
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
        @current_user = decoded_user_from_token(token)
        Current.user = @current_user
        true
      end
    rescue JWT::ExpiredSignature
      Rails.logger.debug "JWT expired"
      render_error("Token has expired", status: :unauthorized)
      false
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound => e
      Rails.logger.debug { "JWT decode failed or user not found: #{e.class} - #{e.message}" }
      render_error("Invalid token", status: :unauthorized)
      false
    end

    def decoded_user_from_token(token)
      payload, = JwtService.decode(token)
      raise JWT::DecodeError, "Nil payload" if payload.nil?

      payload = payload.with_indifferent_access
      user = User.find(payload[:user_id])

      Rails.logger.debug { "Decoded JWT payload: #{payload.inspect}" }
      Rails.logger.debug { "Found user: #{user.inspect}" }

      token_record = Token.find_by(jti: payload[:jti])
      validate_token_record!(token_record, payload)
      validate_token_version!(user, payload)
      validate_token_role!(user, payload)

      user
    end

    def authorize_admin!
      render_error("Forbidden", status: :forbidden) unless Current.user&.admin?
    end

    def current_user
      @current_user || Current.user
    end

    # Global rescue for ActiveRecord::RecordNotFound
    rescue_from ActiveRecord::RecordNotFound do |exception|
      render_not_found(exception.model)
    end

    def validate_token_record!(token_record, payload)
      if token_record&.expired?
        Rails.logger.debug { "Token expired: jti=#{payload[:jti]}" }
        render_error("Token has expired", status: :unauthorized)
        raise JWT::ExpiredSignature
      end
    end

    def validate_token_version!(user, payload)
      if payload[:token_version] != user.token_version
        Rails.logger.debug { "Token version mismatch: #{payload[:token_version]} != #{user.token_version}" }
        render_error("Token has been invalidated", status: :unauthorized)
        raise JWT::DecodeError
      end
    end

    def validate_token_role!(user, payload)
      if payload[:role] != user.role
        Rails.logger.debug { "Role mismatch: #{payload[:role]} != #{user.role}" }
        render_error("User role has changed, please log in again", status: :unauthorized)
        raise JWT::DecodeError
      end
    end
  end
end
