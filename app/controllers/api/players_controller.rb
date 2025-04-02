module Api
  class PlayersController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :validate_api_key

    def create
      @user = User.new(user_params)

      if @user.save
        # Generate a JWT token for API authentication
        token = generate_jwt_token(@user)
        render json: {
          user: @user.as_json(except: [:encrypted_password]),
          token: token
        }, status: :created
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation)
    end

    def validate_api_key
      api_key = request.headers["X-API-Key"]
      unless api_key && Application.find_by(api_key: api_key)
        render json: { error: "Invalid API key" }, status: :unauthorized
      end
    end

    def generate_jwt_token(user)
      JWT.encode(
        {
          sub: user.id,
          exp: 24.hours.from_now.to_i
        },
        Rails.application.credentials.secret_key_base
      )
    end
  end
end
