class Stat
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  CURRENT_STAT_NAME = 'current'

  field :name, :type => String, :default => CURRENT_STAT_NAME
  field :app_version, :type => String

  class << self
    def current
      stat = self.where(:name => CURRENT_STAT_NAME).first
      stat ||= self.create(:name => CURRENT_STAT_NAME, :app_version => '1.2')
    end
  end
end
