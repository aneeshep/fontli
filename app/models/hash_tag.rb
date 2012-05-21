class HashTag
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :name, :type => String
  belongs_to :photo, :index => true # TODO:: remove this after migration
  belongs_to :hashable, :polymorphic => true, :index => true

  validates :name, :hashable_id, :hashable_type, :presence => true
  
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
end
