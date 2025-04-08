module Api
  class SessionsController < BaseController
    skip_before_action :authenticate_user!, only: :create

    def create
      user = User.find_by(email: params[:email])
      if user&.valid_password?(params[:password])
        token = generate_token(user)
        render json: {
          token: token,
          user: {
            id: user.id,
            email: user.email
          }
        }
      else
        render json: { error: "Invalid email or password" }, status: :unauthorized
      end
    end

    def destroy
      current_user.invalidate_token!
      head :no_content
    end

    private

    def generate_token(user)
      payload = {
        user_id: user.id,
        token_version: user.token_version,
        exp: 24.hours.from_now.to_i
      }
      JWT.encode(payload, Rails.application.credentials.secret_key_base)
    end
  end
end
