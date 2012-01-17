class Registration
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :email, :type => String
  index :email

  validates :email, :presence => true, :uniqueness => {:message => 'is already registered'}
  validates :email, :format => /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i, :allow_blank => true

  def self.list
    self.only(:email).collect(&:email)
  end
end
