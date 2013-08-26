class Stat
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  CURRENT_STAT_NAME = 'current'

  field :name, :type => String, :default => CURRENT_STAT_NAME
  field :app_version, :type => String
  field :photo_verify_thumbs_ran_at, :type => Time
  field :photo_fixup_thumbs_ran_at, :type => Time
  field :font_details_cached_at, :type => Time
  field :font_fixup_missing_ran_at, :type => Time
  field :myfonts_api_access_count, :type => Integer
  field :myfonts_api_access_start, :type => Time

  MYFONTS_API_LIMIT = 500 # per hour
  MYFONTS_API_RESET_TIME = 1.hour

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

  def increment_myfonts_api_access_count!
    cur_time = Time.now.utc
    # MyFonts API limit is 500 per hour, so we reset the counts every hour
    if cur_time - self.myfonts_api_access_start <= MYFONTS_API_RESET_TIME
      cnt = self.myfonts_api_access_count
      self.update_attribute(:myfonts_api_access_count, cnt + 1)
    else
      self.update_attributes(myfonts_api_access_start: cur_time, myfonts_api_access_count: 0)
    end
  end

  def can_access_myfonts?
    self.myfonts_api_access_count < (MYFONTS_API_LIMIT - 5) # 5 buffer and thread safety
  end
end
