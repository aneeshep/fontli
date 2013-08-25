class Stat
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  CURRENT_STAT_NAME = 'current'

  field :name, :type => String, :default => CURRENT_STAT_NAME
  field :app_version, :type => String
  field :photo_verify_thumbs_ran_at, :type => Time
  field :photo_fixup_thumbs_ran_at, :type => Time
  field :font_details_cached_at, :type => Time

  class << self
    def current
      stat = self.where(:name => CURRENT_STAT_NAME).first
      stat ||= self.create(:name => CURRENT_STAT_NAME, :app_version => '1.2')
    end
  end

  def misc_attrs
    known_attrs = ['_id', 'app_version', 'created_at', 'name']
    self.attributes.reject { |k, v| known_attrs.include?(k) }
  end
end
