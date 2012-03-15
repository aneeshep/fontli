class Suggestion
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include MongoExtensions

  field :text, :type => String
  field :sugg_type, :type => String
  field :platform, :type => String
  field :os_version, :type => String
  field :app_version, :type => String
  field :notified, :type => Boolean, :default => false

  belongs_to :user, :index => true

  validates :user_id, :text, :presence => true
  validates :text, :length => { :maximum => 500, :allow_blank => true }

  scope :unnotified, where(:notified => false)

  # may require in future
  def mail_to
    case sugg_type
    when /found a bug/
      'support@fontli.com'
    else
      'info@fontli.com'
    end
  end
end
