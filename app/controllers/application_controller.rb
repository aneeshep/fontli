class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :login_required, :set_current_controller

protected

  def login_required
    access_denied unless logged_in?
  end

  def set_current_controller
    Thread.current[:current_controller] = self
  end

  def access_denied
    redirect_to login_url(:default), :notice => "Access denied! Please login."
  end

  def current_user
    @current_user ||= User.find(session[:user_id])
  end
  helper_method :current_user

  def logged_in?
    !session[:user_id].nil?
  end
  helper_method :logged_in?

  def owner?(modal)
    modal.user_id == current_user.id
  end
  helper_method :owner?
end
