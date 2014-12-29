class Stat
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  CURRENT_STAT_NAME = 'current'

  field :name, :type => String, :default => CURRENT_STAT_NAME
  field :app_version, :type => String
  field :photo_verify_thumbs_ran_at, :type => Time
  field :photo_fixup_thumbs_ran_at, :type => Time
  field :photo_likes_count_checked_at, :type => Time, default: '2014-12-24 00:00:00 IST'
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

    def expire_popular_cache!
      Rails.cache.delete 'popular_users'
      Rails.cache.delete 'popular_photos'
      Rails.cache.delete 'popular_fonts'
      Rails.cache.delete 'recent_fonts'
      Rails.cache.delete 'recent_fonts_foto_ids_map'
    end
  end

  def misc_attrs
    known_attrs = ['_id', 'app_version', 'created_at', 'name']
    self.attributes.reject { |k, v| known_attrs.include?(k) }
  end

  def increment_myfonts_api_access_count!
    cur_time = Time.now.utc
    if self.myfonts_api_access_start.nil?
      self.update_attribute(:myfonts_api_access_start, cur_time)
    end

    # MyFonts API limit is 500 per hour, so we reset the counts every hour
    if cur_time - self.myfonts_api_access_start <= MYFONTS_API_RESET_TIME
      cnt = self.myfonts_api_access_count || 0
      self.update_attribute(:myfonts_api_access_count, cnt + 1)
    else
      self.update_attributes(myfonts_api_access_start: cur_time, myfonts_api_access_count: 0)
    end
  end

  # Used in the fonts:build_details_cache script
  # We save atleast 100 calls for the app, so it doesn't break
  def can_access_myfonts?
    cnt = self.myfonts_api_access_count || 0
    cnt < (MYFONTS_API_LIMIT - 100)
  end
end
