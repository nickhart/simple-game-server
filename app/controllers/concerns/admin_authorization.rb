module AdminAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :require_admin!
  end

  private

  def require_admin!
    puts "DEBUG: require_admin! running, current_user=#{@current_user&.email}, role=#{@current_user&.role}"
    unless @current_user&.role == "admin"
      render_error("You must be an admin to perform this action", status: :forbidden)
    end
  end
end
