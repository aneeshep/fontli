require 'auth_client'

class WelcomeController < ApplicationController
  include AuthClient
  skip_before_filter :login_required, :except => [:logout]
  skip_before_filter :set_current_controller, :only => [:keepalive]

  def keepalive
    render :text => 'Success'
  end

  def index
    if logged_in?
      redirect_to feeds_url
    else
      #redirect_to login_url(:default)
      render 'index', :layout => false
    end
  end

  def splash
    if request.post?
      regis = Registration.new(:email => params[:email])
      resp_msg = 'Registered successfully. Thanks for your interest.'
      @resp = regis.save ? resp_msg : regis.errors.full_messages.join
    end
    render 'splash', :layout => false
  end

  def login
    return if request.get?
    self.send(params[:platform] + "_login")
  end

  def signup
    @user = User.new params[:user]
    return if request.get?
    if @user.save
      session[:user_id] = @user.id.to_s # login
      redirect_to feeds_url
    end
  end

  def auth_callback
    self.send(params[:platform] + "_callback")
  end

  def logout
    session[:user_id] = nil
    redirect_to login_url(:default), :notice => 'Logged out.'
  end

  def api_doc
    render 'api_doc', :layout => false
  end

  def permalink
    url = ActiveSupport::Base64.urlsafe_decode64(URI.unescape(params[:url]))
    klass, id = url.split('_')
    @obj = klass.constantize.find(id.to_s)
    @user = @obj.user
    render 'permalink', :layout => false
  rescue
    render :file => 'public/404.html', :status => '404'
  end

private

  def facebook_login
    if fb_authorized?
      usr_obj = fb_client.selection.me.info!
      check_and_handle_fb_user(usr_obj.data)
    else
      auth_url = fb_authorize
      redirect_to auth_url
    end
  end

  def twitter_login
    if twt_authorized?
      usr_hsh = twt_client.info
      check_and_handle_twt_user(usr_hsh)
    else
      resp = twt_get_token
      session[:twt_request_token] = resp.token
      session[:twt_request_token_secret] = resp.secret
      redirect_to resp.authorize_url
    end
  end

  def default_login
    uname, pass = [params[:username], params[:password]]
    if uname.blank? || pass.blank?
      flash.now[:alert] = 'Username or Password is blank!'
      return false
    end
    u = User.login uname, pass
    unless u.nil?
      session[:user_id] = u.id
      redirect_to feeds_url
    else
      flash.now[:alert] = 'Invalid username or password!'
    end
  end

  def twitter_callback
    if params[:denied]
      redirect_to login_url(:default), :alert => 'Unauthorized!'
      return
    end

    # Exchange the request token for an access token.
    resp = twt_authorize params[:oauth_verifier]

    if twt_authorized?
      # Storing the access tokens so we don't have to go back to Twitter again
      # in this session.  We can also consider persisting these details in DB.
      session[:twt_access_token] = resp.token
      session[:twt_secret_token] = resp.secret
      usr_hsh = JSON.parse resp.response.body
      check_and_handle_twt_user(usr_hsh)
    else
      redirect_to login_url(:default), :alert => 'Twitter Auth failed!'
    end
  end

  def facebook_callback
    if params[:error] == "access_denied"
      redirect_to login_url(:default), :alert => 'Unauthorized!'
      return
    end

    token = fb_get_token(params[:code])

    if token
      session[:fb_access_token] = token
      usr_obj = fb_client(true).selection.me.info!
      check_and_handle_fb_user(usr_obj.data)
    else
      redirect_to login_url(:default), :alert => 'Facebook Auth failed!'
    end
  end

  def check_and_handle_twt_user(usr_hsh)
    usr = User.by_extid(usr_hsh['id_str'])
    if usr.nil? # new user
      @user = User.new(
        :username => usr_hsh['screen_name'],
        :email => usr_hsh['email'],
        :full_name => usr_hsh['name'],
        :extuid => usr_hsh['id_str'],
        :description => usr_hsh['description'],
        :website => usr_hsh['url']
      )
      @avatar_url = usr_hsh['profile_image_url']
      render :signup
    else
      session[:user_id] = usr.id
      redirect_to feeds_url
    end
  end

  def check_and_handle_fb_user(usr_obj)
    usr = User.by_extid(usr_obj.id)
    if usr.nil? # new user
      @user = User.new(
        :username => usr_obj.username,
        :email => usr_obj.email,
        :full_name => usr_obj.name,
        :extuid => usr_obj.id,
        :description => usr_obj.bio,
        :website => usr_obj.link
      )
      @avatar_url = fb_client.selection.me.picture
      render :signup
    else
      session[:user_id] = usr.id
      redirect_to feeds_url
    end
  end
end
