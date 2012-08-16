class HashTag
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :name, :type => String
  belongs_to :photo, :index => true # TODO:: remove this after migration
  belongs_to :hashable, :polymorphic => true, :index => true

  validates :name, :hashable_id, :hashable_type, :presence => true

  SOS_REQUEST_HASH_TAG = 'needtypehelp'
  after_create :check_for_sos_request

  class << self
    # matches all hash_tags that starts with 'name' and
    # returns an array #OpenStruct with 'name' and 'photos_count'
    def search(name)
      return [] if name.blank?
      hsh_tags = self.where(:name => /^#{name}.*/i).to_a
      resp = hsh_tags.group_by(&:name)
      resp.collect do |tag_name, hsh_tags|
        fotos_cnt = self.photo_ids(hsh_tags).length
        OpenStruct.new(:name => tag_name, :photos_count => fotos_cnt)
      end
    end

    def photo_ids(hsh_tags)
      hsh_tags.collect{ |ht| ht.photo_ids}.flatten.uniq
    end
  end

  def photo_ids
    self.hashable.photo_ids
  end

private

  def check_for_sos_request
    return true unless self.name.downcase == SOS_REQUEST_HASH_TAG
    return true unless self.hashable.respond_to?(:font_help)
    self.hashable.update_attribute(:font_help, true)
    true
  end
end
