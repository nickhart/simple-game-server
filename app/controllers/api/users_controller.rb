module Api
  class UsersController < BaseController
    skip_before_action :authenticate_user!, only: [:create]
    before_action :authenticate_user!, only: %i[show update destroy]
    before_action :authorize_user!, only: %i[show update destroy], if: -> { params[:id].present? && params[:id] != "me" }

    def show
      if params[:id] == "me"
        render_success(@current_user)
      elsif params[:id].to_i == @current_user.id
        render_success(@current_user)
      else
        render_forbidden("Access denied")
      end
    end

    def create
      user = User.new(user_params)
      user.role = "player"

      if user.save
        render_success(user, status: :created)
      else
        render_unprocessable_entity(user.errors.full_messages + user.player&.errors&.full_messages.to_a)
      end
    end

    def update
      if @current_user.update(user_params)
        render_success(@current_user)
      else
        render_unprocessable_entity(@current_user.errors.full_messages)
      end
    end

    def destroy
      @current_user.destroy
      render_success(message: "User deleted")
    end

    private

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation)
    end

    def authorize_user!
      render_forbidden("Forbidden") unless params[:id].to_i == @current_user.id
    end
  end
end
