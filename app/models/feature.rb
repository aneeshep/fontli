class Feature
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  VALID_FEATURES = ['inktober']

  field :name, :type => String
  field :active, :type => Boolean, :default => false

  validates :name, presence: true, inclusion: VALID_FEATURES
end
