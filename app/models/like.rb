class Like
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include MongoExtensions
  include Scorable
  include Notifiable

  belongs_to :user, :index => true, :counter_cache => true
  belongs_to :photo, :index => true, :counter_cache => true

  validates :user_id, :uniqueness => { :scope => :photo_id, :message => "has already liked!" }

  default_scope lambda { where(:user_id.nin => User.inactive_ids) }

  def notif_extid
    self.photo_id.to_s
  end

  def notif_context
    ['has liked']
  end
end
