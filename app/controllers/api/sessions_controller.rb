module Api
  class SessionsController < BaseController
    skip_before_action :authenticate_user!

    def create
      user = User.find_by(email: params[:email])

      if user&.valid_password?(params[:password])
        token = generate_jwt_token(user)
        render json: { token: token }
      else
        render json: { error: "Invalid email or password" }, status: :unauthorized
      end
    end

    private

    def generate_jwt_token(user)
      JWT.encode(
        { sub: user.id, exp: 24.hours.from_now.to_i },
        Rails.application.credentials.secret_key_base
      )
    end
  end
end
