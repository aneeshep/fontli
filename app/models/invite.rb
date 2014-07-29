require 'api_helper'
class Invite
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :email, :type => String
  field :extuid, :type => String
  field :platform, :type => String, :default => 'default'
  field :full_name, :type => String

  belongs_to :user, :index => true

  index :email => 1
  index :extuid => 1, :platform => 1
  PLATFORMS = ['twitter', 'facebook']

  validates :email, :format => /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i, :allow_blank => true
  validates :platform, :presence => true, :if => Proc.new { |rec| rec.email.blank? }
  validates :platform, :inclusion => { :in => PLATFORMS, :allow_blank => true }
  validate  :extuid_or_email_required, :on => :create

  after_create :trigger_invitation!

  # create friendships b/w the new_user signed up and the user invited.
  def mark_as_friend(new_user)
    self.user.follows.create(:follower_id => new_user.id)
    new_user.follows.create(:follower_id  => self.user.id)
    self.destroy # not req any more!
  end

  def invite_state
    'Invited'
  end

  def error_resp
    "#{self.error_resp_key}:: #{self.errors.full_messages.join(', ')}"
  end

  def error_resp_key
    self.extuid || self.email || self.full_name || 'null'
  end

private

  def trigger_invitation!
    return true unless self.email
    to_user = User.new(:username => self.full_name, :email => self.email)
    #UserMailer.invite_email(self.user, to_user).deliver
  end

  def extuid_or_email_required
    error_map = ApiHelper::ERROR_MESSAGE_MAP
    invald    = self.email.nil? && self.extuid.nil?
    self.errors.add(:base, error_map[:extuid_email_req]) if invald
  end
end
