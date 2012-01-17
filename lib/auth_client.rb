# Interacts with FB/Twitter oauth apis
# using fbgraph and twitter_oauth gems resp.
# Designed to be included to any controller.
module AuthClient
  SOCIAL_API_CREDS_MAP = YAML::load_file File.join(Rails.root, 'config/social_api.yml')

  #FB methods
  def fb_client(reload = false)
    opts = {
      :client_id => fb_config['app_key'],
      :secret_id => fb_config['app_secret'],
      :token => session[:fb_access_token]
    }

    @fb_client = FBGraph::Client.new(opts) if reload
    @fb_client ||= FBGraph::Client.new(opts)
  end

  def fb_authorize
    fb_client.authorization.authorize_url(
      :redirect_uri => fb_config['callback_url'],
      :scope => 'email,publish_stream'
    )
  end

  def fb_get_token(code)
    fb_client.authorization.process_callback(code,
      :redirect_uri => fb_config['callback_url']
    )
  end

  # TODO:: we may need to check the access token validity as well.
  def fb_authorized?
    !session[:fb_access_token].blank?
  end

  def fb_config
    SOCIAL_API_CREDS_MAP['facebook']
  end

  # Twitter methods
  def twt_client
    opts = {
      :consumer_key    => twt_config['app_key'],
      :consumer_secret => twt_config['app_secret'],
      :token => session[:twt_access_token],
      :secret => session[:twt_secret_token]
    }
    @twt_client ||= TwitterOAuth::Client.new(opts)
  end

  def twt_get_token
    twt_client.request_token(
      :oauth_callback => twt_config['callback_url']
    )
  end

  def twt_authorize(verifier)
    twt_client.authorize(
      session[:twt_request_token],
      session[:twt_request_token_secret],
      :oauth_verifier => verifier
    )
  end

  def twt_authorized?
    twt_client.authorized?
  end

  def twt_config
    SOCIAL_API_CREDS_MAP['twitter']
  end
end
