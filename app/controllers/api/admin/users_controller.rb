module Api
  module Admin
    class UsersController < BaseController
      include AdminAuthorization

      def index
        users = User.all
        render_success(users)
      end

      def show
        user = User.find(params[:id])
        render_success(user)
      end

      def update
        user = User.find(params[:id])
        if user.update(user_params)
          render_success(user)
        else
          render_error(user.errors.full_messages)
        end
      end

      def make_admin
        user = User.find(params[:id])
        user.make_admin!
        render_success(user)
      end

      def remove_admin
        user = User.find(params[:id])
        user.remove_admin!
        render_success(user)
      end

      private

      def user_params
        params.require(:user).permit(:email)
      end
    end
  end
end
