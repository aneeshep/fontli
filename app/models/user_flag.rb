class UserFlag
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  belongs_to :user, :index => true, :counter_cache => true
  belongs_to :from_user, :class_name => 'User', :index => true

  validates :from_user_id, :uniqueness => { :scope => :user_id, :message => "has already flagged!" }
end
