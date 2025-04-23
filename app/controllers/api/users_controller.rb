module Api
  class UsersController < BaseController
    skip_before_action :authenticate_user!, only: [:create]
    before_action :authenticate_user!, only: %i[show update destroy me]
    before_action :authorize_user!, only: %i[show update destroy]

    def show
      render_success(@current_user)
    end

    def create
      user = User.new(user_params)
      user.role = "player"

      if user.save
        render_success(user, status: :created)
      else
        render_error(user.errors.full_messages + user.player&.errors&.full_messages.to_a, status: :unprocessable_entity)
      end
    end

    def update
      if @current_user.update(user_params)
        render_success(@current_user)
      else
        render_error(@current_user.errors.full_messages, status: :unprocessable_entity)
      end
    end

    def destroy
      @current_user.destroy
      render_success(message: "User deleted")
    end

    def me
      render_success(@current_user)
    end

    private

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation)
    end

    def authorize_user!
      render_error("Forbidden", status: :forbidden) unless params[:id].to_i == @current_user.id
    end
  end
end
