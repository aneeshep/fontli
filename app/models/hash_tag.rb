class HashTag
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :name, :type => String
  belongs_to :photo, :index => true

  validates :name, :photo_id, :presence => true
  
  class << self
    # matches all hash_tags that starts with 'name' and
    # returns an array #OpenStruct with 'name' and 'photos_count'
    def search(name)
      return [] if name.blank?
      hsh_tags = self.where(:name => /^#{name}.*/).to_a
      resp = hsh_tags.group_by(&:name)
      resp.collect do |tag_name, hsh_tags|
        OpenStruct.new(:name => tag_name, :photos_count => hsh_tags.length)
      end
    end
  end
end
