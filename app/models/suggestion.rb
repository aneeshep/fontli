class Suggestion
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include MongoExtensions

  field :text, :type => String

  belongs_to :user, :index => true

  validates :user_id, :text, :presence => true
  validates :text, :length => { :maximum => 500, :allow_blank => true }
end
