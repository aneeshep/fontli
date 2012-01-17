class Flag
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  belongs_to :user, :index => true
  belongs_to :photo, :index => true

  validates :user_id, :uniqueness => { :scope => :photo_id, :message => "has already flagged!" }
end
