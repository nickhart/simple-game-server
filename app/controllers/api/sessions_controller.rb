module Api
  class SessionsController < BaseController
    skip_before_action :authenticate_user!, only: %i[create refresh]

    def create
      session_params = params.require(:session).permit(:email, :password)
      user = User.find_by(email: session_params[:email])
      if user&.valid_password?(session_params[:password])
        access_token = Token.create_access_token(user)
        refresh_token = Token.create_refresh_token(user)

        render json: {
          access_token: access_token.user.to_jwt(access_token),
          refresh_token: refresh_token.user.to_jwt(refresh_token),
          user: {
            id: user.id,
            email: user.email,
            role: user.role
          }
        }
      else
        render_error("Invalid email or password", status: :unauthorized)
      end
    end

    def refresh
      refresh_token = params[:refresh_token] || params.dig(:session, :refresh_token)
      return render_error("Refresh token is required", status: :unauthorized) unless refresh_token

      payload = JwtService.decode(refresh_token)
      user = verify_refresh_token(payload)

      if user
        access_token = Token.create_access_token(user)
        render json: { access_token: access_token.user.to_jwt(access_token) }
      else
        render_error("Invalid refresh token", status: :unauthorized)
      end
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render_error("Invalid refresh token", status: :unauthorized)
    end

    def destroy
      current_user.invalidate_token!
      head :no_content
    end

    private

    def verify_refresh_token(payload)
      return unless payload

      token = Token.find_by(jti: payload[:jti])
      user = User.find_by(id: payload[:user_id])
      return unless token&.status_active?
      return unless user&.token_version == payload[:token_version]

      user
    end
  end
end
