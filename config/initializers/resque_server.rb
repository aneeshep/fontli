require 'resque/server'

# Set the AUTH env variable to your basic auth password to protect Resque.
AUTH_PASSWORD = SECURE_TREE['resque_auth']
if AUTH_PASSWORD
  Resque::Server.use Rack::Auth::Basic do |username, password|
    password == AUTH_PASSWORD
  end
end
