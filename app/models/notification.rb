class Notification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :unread, :type => Boolean, :default => true
  # store related photo_id(for like) or font_id(for font_tag) to avoid additional DB hits
  field :extid, :type => String

  belongs_to :from_user, :class_name => 'User'
  belongs_to :to_user, :class_name => 'User', :index => true
  belongs_to :notifiable, :polymorphic => true, :index => true

  validates :from_user_id, :to_user_id, :presence => true
  validates :notifiable_id, :notifiable_type, :presence => true

  default_scope desc(:created_at)
  scope :unread, where(:unread => true)

  class << self
    def find_for(tgt_id, extid, not_type)
      self.where(:to_user_id => tgt_id, :extid => extid, :notifiable_type => not_type).first
    end
  end

  def message
    msg = [self.from_user.full_name]
    msg << self.notifiable.notif_context
    msg << self.user_context
    msg << ['photo']
    msg.join(' ')
  end

  def user_context
    ["your"] #static for now
  end

private

  # sends push notification for every new notification, when cnt < 6
  # and one push notification for 6th, 16th and 31st notification.
  def send_apn
    to_usr = self.to_user
    return true if to_usr.iphone_token.blank?
    notif_cnt = to_usr.notifications.unread.count
    opts = { :badge => notif_cnt }
    if notif_cnt < 6
      APN.notify(to_usr.iphone_token, opts)
    elsif [6, 16, 31].include?(notif_cnt)
      opts = opts.merge(:alert => "You have more than #{notif_cnt - 1} pending notifications", :sound => true)
      APN.notify(to_usr.iphone_token, opts)
    end
    true
  end
end
