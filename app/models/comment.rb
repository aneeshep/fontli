class Comment
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include MongoExtensions
  include Scorable
  include Notifiable

  field :body, :type => String
  field :font_ids, :type => Array

  belongs_to :photo, :index => true
  belongs_to :user, :index => true
  has_many :mentions, :as => :mentionable, :dependent => :destroy

  validates :user_id, :photo_id, :presence => true
  validates :body, :length => { :maximum => 300, :allow_blank => true }

  after_create :populate_mentions

  def fonts
    return [] if self.font_ids.blank?
    @fonts ||= Font.where(:_id.in => self.font_ids).to_a
  end

  def username
    @usr ||= self.user
    @usr.username
  end

  def user_url_thumb
    @usr ||= self.user
    @usr.url_thumb
  end

  # don't notify for a comment, if the photo publisher is also mentioned.
  def can_notify?
    self.mentions.where(:user_id => notif_target_user_id).first.nil?
  end

  def notif_context
    ['has commented']
  end

private

  def populate_mentions
    mnts = Photo.check_mentions_in(self.body)
    mnts.each { |hsh| self.mentions.create(hsh) }
    true
  end
end
