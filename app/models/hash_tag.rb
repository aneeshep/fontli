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
        foto_ids = hsh_tags.collect{ |ht| ht.hashable.photo_ids}.flatten.uniq
        fotos_cnt = foto_ids.length
        OpenStruct.new(:name => tag_name, :photos_count => fotos_cnt)
      end
    end
  end
end
