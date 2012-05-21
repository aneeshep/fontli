# triggers to create notifications.
module Notifiable

  def self.included(klass)
    super
    klass.class_eval do
      has_many :notifications, :as => :notifiable, :dependent => :destroy

      after_create :create_app_notification
    end
  end

  # default source_user, override if n/a
  def notif_source_user_id
    self.user_id
  end

  # default target_user, override if n/a
  def notif_target_user_id
    self.photo.user_id
  end

  def can_notify?
    group_notify_class? ? can_group_notify? : true # by default
  end

  # Acts like FB. Group notifications for similar events.
  # Ex.,Create a new notification only for the first like for a given foto.
  # From then, just mark the existing notification as unread.
  def can_group_notify?
    tgt_id, src_id = [self.notif_target_user_id, self.notif_source_user_id]
    return false if src_id == tgt_id
    notif = Notification.find_for(tgt_id, self.notif_extid, self.class.to_s)
    return true if notif.nil?
    # force the update query to set the updated_at.
    status = notif.update_attributes(:unread => true, :updated_at => Time.now.utc) == false
    # Trigger the apn notification for every single activity.
    Notification.new(
      :from_user_id => src_id,
      :to_user_id => tgt_id,
      :notifiable => self
    ).send(:send_apn) && status
  end

private

  def group_notify_class?
    ['Like', 'FontTag'].include? self.class.to_s
  end

  def create_app_notification
    return true unless can_notify?
    src_usr_id = self.notif_source_user_id
    tgt_usr_ids = [self.notif_target_user_id].flatten
    extid = self.respond_to?(:notif_extid) ? self.notif_extid : nil
    # handle cases like users commenting to their own photo.
    tgt_usr_ids -= [src_usr_id]
    tgt_usr_ids.each do |tgt_uid|
      notif = self.notifications.build(
        :from_user_id => src_usr_id,
        :to_user_id   => tgt_uid,
        :extid        => extid)
      notif.save
    end
    true
  end
end
