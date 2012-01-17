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

  def mob_req?
    mob_agent_regex = /iphone|android/
    agent = request.headers["HTTP_USER_AGENT"].to_s.downcase
    Rails.logger.info "----my_user_agent = #{agent}----"
    !agent.match(mob_agent_regex).nil?
  end
  helper_method :mob_req?
end
