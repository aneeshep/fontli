class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :login_required, :set_current_controller

protected

  def login_required
    access_denied unless logged_in?
  end

  def admin_required
    admin_users = Fontli.load_erb_config('admin_creds.yml')
    authenticate_or_request_with_http_digest do |username|
      admin_users[username]
    end
  end

  def set_current_controller
    Thread.current[:current_controller] = self
  end

  def access_denied
    msg = "Access denied! Please login."
    redirect_to login_url(:default), :notice => msg
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
    mob_agent_regex = /iphone|android\s(1|2)/ # android 3|4 are tablets
    agent = request.headers["HTTP_USER_AGENT"].to_s.downcase
    !agent.match(mob_agent_regex).nil?
  end
  helper_method :mob_req?
end
