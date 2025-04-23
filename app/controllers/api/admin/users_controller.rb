module Api
  module Admin
    class UsersController < BaseController
      include AdminAuthorization
      skip_before_action :require_admin!, only: [:create]
      skip_before_action :authenticate_user!, only: [:create]

      def index
        users = User.all
        render_success(users)
      end

      def show
        user = User.find(params[:id])
        render_success(user)
      end

      def create
        if allow_admin_creation?
          user = User.new(user_params)
          user.role = "admin"
          if user.save
            render_success(user, status: :created)
          else
            Rails.logger.debug(user.errors.full_messages.inspect)
            render_error(user.errors.full_messages, status: :unprocessable_entity)
          end
        else
          render_error("Admin user creation is not allowed", status: :forbidden)
        end
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

      def allow_admin_creation?
        User.count.zero? || User.where(role: "admin").count.zero?
      end

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end
    end
  end
end
