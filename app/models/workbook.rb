class Workbook
  include Mongoid::Document
  include MongoExtensions
  include Mongoid::Timestamps
  include MongoExtensions::CounterCache

  field :title, :type => String
  field :description, :type => String
  field :photos_count, :type => Integer, :default => 0

  has_many :photos, :dependent => :destroy
  has_many :hash_tags, :as => :hashable, :autosave => true, :dependent => :destroy
  belongs_to :user

  validates :title, 
    :presence   => true, 
    :uniqueness => { :scope => :user_id }, 
    :length     => { :maximum => 500, :allow_blank => true }
  validates :description, :length => { :maximum => 500, :allow_blank => true }

  attr_accessor :foto_ids, :removed_foto_ids, :hashes
  after_save :associate_new_photos, :unlink_removed_photos, :populate_hash_tags

  class << self
    def [](wbid)
      self.where(:_id => wbid).first
    end
  end

  def photo_ids
    self.photos.only(:_id).collect(&:_id)
  end

private

  def associate_new_photos
     return true if self.foto_ids.blank?
     Photo.where(:_id.in => self.foto_ids).update_all(:workbook_id => self.id)
  end

  def unlink_removed_photos
     return true if self.removed_foto_ids.blank?
     Photo.where(:_id.in => self.removed_foto_ids).update_all(:workbook_id => nil)
  end

  def populate_hash_tags
    return true if self.hashes.blank?
    self.hashes.each { |h| self.hash_tags.create(h) }
  end
end
