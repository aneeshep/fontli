class FavFont
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include MongoExtensions

  belongs_to :user, :index => true, :counter_cache => true
  belongs_to :font, :index => true

  validates :user_id, :font_id, :presence => true
  validates :user_id, :uniqueness => { :scope => :font_id, :message => "has already favorited!" }
end
