class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  # before_action :allow_iframe_requests

  def require_administrator
    unless current_user.try(:admin?)
      redirect_to root_url
    end
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end

  def confirm_i_agree
    if current_user && !current_user.i_agree
      redirect_to terms_agreement_path
      return
    end
  end

  def current_location
    if session[:current_location_id].present?
      @location = Location.friendly.find(session[:current_location_id])
    elsif params[:location_id]
      session[:current_location_id] = params[:location_id]
      @location = Location.friendly.find(params[:location_id])
    else
      @location = Location.first
      session[:current_location_id] = @location.id
    end
    @location
  end
  helper_method :current_location

end
