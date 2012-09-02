class Comment
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include MongoExtensions
  include Scorable
  include MongoExtensions::DynamicScope

  field :body, :type => String
  field :font_tag_ids, :type => Array
  field :foto_ids, :type => Array  #mentioned photo_ids

  belongs_to :photo, :index => true
  belongs_to :user, :index => true
  has_many :mentions, :as => :mentionable, :dependent => :destroy

  validates :user_id, :photo_id, :presence => true
  validates :body, :length => { :maximum => 500, :allow_blank => true }

  after_create :populate_mentions
  after_destroy :delete_assoc_font_tags
  include Notifiable

  default_scope lambda { {:where => { :user_id.nin => User.inactive_ids }} }

  class << self
    # delete_comment api finds comment bypassing the assoc photo, though its not recommended.
    def [](cmt_id)
      self.where(:_id => cmt_id).first
    end
  end

  #Overriding the notification method
  def notif_target_user_id
    self.photo.comments.only(:user_id).collect(&:user_id)
  end

  # return a custom font collection(w/ coords) tagged with this comment.
  def fonts
    return [] if self.font_tag_ids.blank?
    return @fonts unless @fonts.nil? # compute once per instance
    fnt_tags = FontTag.where(:_id.in => self.font_tag_ids).to_a
    fnt_ids = fnt_tags.collect(&:font_id).uniq
    fnts = Font.where(:_id.in => fnt_ids).to_a.group_by(&:id)
    @fonts = fnt_tags.collect do |ft|
      f = fnts[ft.font_id].first
      OpenStruct.new(f.attributes.update(
        :id => f.id,
        :tags_count => f.tags_count,
        :my_agree_status => f.my_agree_status,
        :img_url => f.img_url,
        :my_fav? => f.my_fav?,
        :coords => ft.coords) )
    end
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

  def fotos
    return [] if self.foto_ids.blank?
    Photo.where(:_id.in => self.foto_ids).only(:id, :data_filename).to_a
  end

private

  def populate_mentions
    mnts = Photo.check_mentions_in(self.body)
    mnts.each { |hsh| self.mentions.create(hsh) }
    true
  end

  def delete_assoc_font_tags
    return true if self.font_tag_ids.empty?
    fnt_tgs = FontTag.where(:_id.in => self.font_tag_ids).to_a
    # destroy the font all together if that's the last tag on it.
    fnt_tgs.each { |ft| ft.font.tags_count == 1 ? ft.font.destroy : ft.destroy }
    true
  end
end
