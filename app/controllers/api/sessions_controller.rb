module Api
  class SessionsController < BaseController
    skip_before_action :authenticate_user!

    def create
      user = User.find_by(email: params[:email])
      if user&.valid_password?(params[:password])
        token = JWT.encode(
          { sub: user.id, exp: 24.hours.from_now.to_i },
          Rails.application.credentials.secret_key_base
        )
        render json: { token: token, user: { id: user.id, email: user.email } }
      else
        render json: { error: "Invalid email or password" }, status: :unauthorized
      end
    end
  end
end
