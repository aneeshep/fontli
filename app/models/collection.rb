class Collection
  include Mongoid::Document
  include MongoExtensions
  include Mongoid::Timestamps

  field :name, :type => String
  field :description, :type => String
  field :active, :type => Boolean, :default => false

  belongs_to :user
  has_and_belongs_to_many :photos

  validates :name, 
    :presence   => true, 
    :uniqueness => true, 
    :length     => { :maximum => 100, :allow_blank => true }
  validates :description,
    :length     => { :maximum => 500, :allow_blank => true }

  scope :active, where(:active => true)

  after_create :auto_follow

  class << self
    def [](id)
      self.where(:_id => id).first
    end
  end

  # memoized version of photos to be used in collection_detail api
  def fotos
    @fotos ||= self.photos.to_a
  end

  def photos_count
    self.photos.count
  end

  # url of the recent photo added to this collection
  def cover_photo_url
    self.photos.desc(:created_at).only(:id, :data_filename).first.try(:url_large)
  end

  # TODO: yet to test
  def followed_users
    @followed_users ||= follow_scope.to_a
  end

  def follows_count
    @follows_count ||= follow_scope.count
  end

  # is current user following this collection
  def can_follow?
    current_user.can_follow_collection?(self)
  end

  # custom collections are created by our users
  # while the system collections are created by admin (no user_id)
  def custom?
    self.user_id.present?
  end

  private

  def follow_scope
    User.following_collection(self.id)
  end

  def auto_follow
    self.user.follow_collection(self) if custom?
  end
end
