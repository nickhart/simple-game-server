module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authenticate_user!

    private

    def authenticate_user!
      token = request.headers["Authorization"]&.split(" ")&.last
      return render_unauthorized unless token

      begin
        decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base)
        @current_user = User.find(decoded_token[0]["sub"])
      rescue JWT::DecodeError
        render_unauthorized
      end
    end

    def render_unauthorized
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
