class ApiSession
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include MongoExtensions

  field :device_id, :type => String
  field :auth_token, :type => String
  field :expires_at, :type => Time

  index :auth_token => 1, :device_id => 1

  SESSION_EXPIRY_TIME = 40.weeks

  belongs_to :user, :index => true

  validates :user_id, :device_id, :presence => true

  def self.[](token, devic_id)
    where(:auth_token => token, :device_id => devic_id).first
  end

  def activate
    self.auth_token = generate_rand(16)
    self.expires_at = current_time + SESSION_EXPIRY_TIME
    self.save ? CGI.escape(token_str) : [nil, :unable_to_save]
  end

  def deactivate
    self.auth_token = nil
    self.expires_at = current_time
    self.save || [nil, :unable_to_save]
  end

  def active?
    self.expires_at > current_time
  end

  private

  def token_str
    self.auth_token + '||' + self.device_id
  end
end
