module AdminAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :require_admin!
  end

  private

  def require_admin!
    unless @current_user&.role == "admin"
      render_error("You must be an admin to perform this action", status: :forbidden)
    end
  end
end
