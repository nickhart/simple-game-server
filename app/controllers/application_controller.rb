class ApplicationController < ActionController::Base
  # CSRF protection enabled by default for all controllers
  # API controllers will specifically disable it

  before_action :set_current_user

  private

  def set_current_user
    Current.user = current_user
  end

  def json_request?
    request.format.json?
  end
end
