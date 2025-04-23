class ApplicationController < ActionController::Base
  # CSRF protection enabled by default for all controllers
  # API controllers will specifically disable it

  before_action :set_current_user
  before_action :debug_auth_headers, if: -> { Rails.env.test? || Rails.env.ci? }

  private

  def set_current_user
    Current.user = current_user
  end

  def json_request?
    request.format.json?
  end

  def debug_auth_headers
    Rails.logger.warn("🔐 Authorization header: #{request.headers['Authorization'].inspect}")
    Rails.logger.warn("📦 Content-Type: #{request.headers['Content-Type'].inspect}")
    Rails.logger.warn("🧾 Accept: #{request.headers['Accept'].inspect}")
  end

end
