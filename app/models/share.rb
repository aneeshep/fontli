class Share
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include MongoExtensions
  include Scorable

  belongs_to :user, :index => true
  belongs_to :photo, :index => true

  validates :user_id, :photo_id, :presence => true

  def passive_points
    owner_share? ? 0 : 5
  end

  def owner_share?
    self.user_id == self.photo.user_id
  end
end
