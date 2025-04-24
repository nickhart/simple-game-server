module Api
  # TokensController handles user sessions and authentication, including token creation, refresh, and invalidation.
  class TokensController < BaseController
    skip_before_action :authenticate_user!, only: %i[create refresh]

    def create
      begin
        session_params = params.require(:session).permit(:email, :password)
      rescue ActionController::ParameterMissing, ActionController::UnpermittedParameters
        return render_bad_request("Invalid session parameters")
      end

      user = User.find_by(email: session_params[:email])
      if user&.valid_password?(session_params[:password])
        access_token = Token.create_access_token(user)
        refresh_token = Token.create_refresh_token(user)

        render_success({
                         access_token: access_token.user.to_jwt(access_token),
                         refresh_token: refresh_token.user.to_jwt(refresh_token),
                         user: {
                           id: user.id,
                           email: user.email,
                           role: user.role
                         }
                       })
      else
        render_unauthorized("Invalid email or password")
      end
    end

    def refresh
      begin
        token_params = params.require(:token).permit(:refresh_token)
      rescue ActionController::ParameterMissing
        return render_bad_request("Refresh token is required")
      end

      refresh_token = token_params[:refresh_token]
      payload = JwtService.decode(refresh_token)
      user = verify_refresh_token(payload)

      if user
        access_token = Token.create_access_token(user)
        render_success({
                         access_token: access_token.user.to_jwt(access_token)
                       })
      else
        render_unauthorized("Invalid refresh token")
      end
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render_unauthorized("Invalid refresh token")
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
