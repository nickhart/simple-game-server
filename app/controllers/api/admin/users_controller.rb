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
      rescue ActiveRecord::RecordNotFound
        render_not_found("User not found")
      end

      def create
        if allow_admin_creation?
          user = User.new(user_params)
          user.role = "admin"
          if user.save
            render_success(user, status: :created)
          else
            render_unprocessable_entity(user.errors.full_messages)
          end
        else
          render_forbidden("Admin user creation is not allowed")
        end
      end

      def update
        user = User.find(params[:id])
        if user.update(user_params)
          render_success(user)
        else
          render_unprocessable_entity(user.errors.full_messages)
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found("User not found")
      end

      def make_admin
        user = User.find(params[:id])
        if user.make_admin!
          render_success(user)
        else
          render_unprocessable_entity("Unable to promote user to admin")
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found("User not found")
      end

      def remove_admin
        user = User.find(params[:id])
        if user.remove_admin!
          render_success(user)
        else
          render_unprocessable_entity("Unable to demote user from admin")
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found("User not found")
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
