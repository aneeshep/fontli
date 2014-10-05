class Collection
  include Mongoid::Document
  include MongoExtensions
  include Mongoid::Timestamps

  field :name, :type => String
  field :description, :type => String

  has_and_belongs_to_many :photos, :dependent => :destroy

  validates :name, 
    :presence   => true, 
    :uniqueness => true, 
    :length     => { :maximum => 100, :allow_blank => true }
  validates :description, :length => { :maximum => 500, :allow_blank => true }

  class << self
    def [](id)
      self.where(:_id => id).first
    end
  end

  def photo_ids
    self.photos.pluck(:id)
  end
end
