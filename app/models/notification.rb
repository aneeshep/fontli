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

  default_scope desc(:updated_at, :unread)
  scope :unread, where(:unread => true)

  after_create :send_apn

  class << self
    def find_for(tgt_id, extid, not_type)
      self.where(:to_user_id => tgt_id, :extid => extid, :notifiable_type => not_type).first
    end
  end

  def message
    frm_usr = self.from_user
    case self.notifiable_type.to_s
    when /Like/
      "#{frm_usr.username} liked your post."
    when /Comment/
      "#{frm_usr.username} commented on your post."
    when /Mention/
      cntxt = self.notifiable.mentionable_type == 'Comment' ? 'comment' : 'post'
      "#{frm_usr.username} mentioned you in a #{cntxt}."
    when /FontTag/
      "#{frm_usr.username} spotted on your post."
    when /Agree/
      "#{frm_usr.username} agreed your spotting."
    when /Follow/
      "#{frm_usr.username} started following your feed."
    else
      "You have an unread notification!"
    end
  end

private

  # sends push notification for every new notification
  def send_apn
    to_usr = self.to_user
    return true if to_usr.iphone_token.blank?
    notif_cnt = to_usr.notifications.unread.count
    opts = { :badge => notif_cnt, :alert => self.message, :sound => true }
    APN.notify(to_usr.iphone_token, opts)
    true
  end
end
