class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_filter :allow_iframe_requests

  def require_administrator
    unless current_user.try(:admin?)
      redirect_to root_url
    end
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end

end
