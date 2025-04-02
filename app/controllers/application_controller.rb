class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Skip CSRF protection for API requests
  skip_before_action :verify_authenticity_token, if: :json_request?

  before_action :set_current_user

  private

  def set_current_user
    Current.user = current_user
  end

  def json_request?
    request.format.json?
  end
end
