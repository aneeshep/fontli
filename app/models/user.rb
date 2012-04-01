require 'digest/sha1'
class User
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include MongoExtensions

  field :username, :type => String
  field :full_name, :type => String
  field :email, :type => String
  field :hashed_password, :type => String
  field :salt, :type => String
  field :description, :type => String
  field :website, :type => String
  field :avatar_filename, :type => String
  field :avatar_content_type, :type => String
  field :avatar_size, :type => Integer
  field :avatar_dimension, :type => String
  field :extuid, :type => String
  field :platform, :type => String, :default => 'default'
  field :iphone_token, :type => String
  field :iphone_token_updated_at, :type => DateTime
  field :admin, :type => Boolean, :default => false
  field :expert, :type => Boolean, :default => false
  field :points, :type => Integer, :default => 5
  field :active, :type => Boolean, :default => true
  field :suspended_reason, :type => String
  field :fav_fonts_count, :type => Integer, :default => 0
  field :likes_count, :type => Integer, :default => 0
  field :follows_count, :type => Integer, :default => 0
  field :user_flags_count, :type => Integer, :default => 0

  include MongoExtensions::CounterCache
  index :username, :unique => true
  index :email, :unique => true

  FOTO_DIR = File.join(Rails.root, 'public/avatars')
  FOTO_PATH = File.join(FOTO_DIR, ':id/:style.:extension')
  DEFAULT_AVATAR_PATH = File.join(Rails.root, 'public/avatar_missing_:style.png')
  ALLOWED_TYPES = ['image/jpg', 'image/jpeg', 'image/png']
  PLATFORMS = ['twitter', 'facebook']
  THUMBNAILS = {:thumb => '75x75', :large => '150x150'}
  LEADERBOARD_LIMIT = 20
  ALLOWED_FLAGS_COUNT = 5

  has_many :photos, :dependent => :destroy
  has_many :fonts, :dependent => :destroy
  has_many :fav_fonts, :dependent => :destroy
  has_many :notifications, :foreign_key => :to_user_id, :dependent => :destroy
  has_many :follows, :dependent => :destroy
  has_many :likes, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :user_flags, :dependent => :destroy
  has_many :invites, :dependent => :destroy
  has_many :sessions, :class_name => 'ApiSession', :dependent => :destroy

  validates :email, :username, :presence => true, :uniqueness => { :case_sensitive => false }
  validates :password, :presence => true, :on => :create
  validates :username, :length => 5..15, :allow_blank => true
  validates :username, :format => {:with => /^[A-Z0-9._-]+$/i, :allow_blank => true, :message => "can only be alphanumeric with _-. chars."}
  validates :email, :format => /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i, :allow_blank => true
  validates :password, :length => 6..15, :confirmation => true, :allow_blank => true
  validates :avatar_size,
    :inclusion => { :in => 0..(3.megabytes), :message => "should be less than 3MB" },
    :if => lambda { has_avatar? }
  validates :avatar_content_type,
    :inclusion => { :in => ALLOWED_TYPES, :message => 'should be jpg/gif' },
    :if => lambda { has_avatar? }
  validates :extuid, :presence => true, :if => lambda { PLATFORMS.include? self.platform } 

  attr_accessor :password, :password_confirmation, :avatar, :avatar_url, :friendship_state, :invite_state

  before_save :set_hashed_password
  after_save :save_avatar_to_file, :save_thumbnail
  after_destroy :delete_file

  default_scope where(:active => true, :user_flags_count.lt => ALLOWED_FLAGS_COUNT)
  scope :non_admins, where(:admin => false)
  scope :experts, where(:expert => true)
  scope :flagged, where(:user_flags_count.gte => ALLOWED_FLAGS_COUNT).desc(:user_flags_count)
  scope :leaders, non_admins.desc(:points).limit(LEADERBOARD_LIMIT)

  class << self
    def [](uname)
      self.where(:username => uname).first
    end

    def fontli
      self['fontli']
    end

    def by_id(uid)
      self.where(:_id => uid.to_s).first
    end

    def by_extid(exid)
      self.where(:extuid => exid.to_s).first
    end

    def by_uname_or_email(val)
      # self.any_of(:username => val, :email => val) # Doesn't work
      u = self.where(:username => val).first
      u ||= self.where(:email => val).first
    end

    def search(uname)
      return [] if uname.blank?
      res = self.where(:username => /^#{uname}.*/i).to_a
      res << self.where(:full_name => /^#{uname}.*/i).to_a
      res.flatten.uniq(&:id)
    end

    # uname can be username or email
    def login(uname, pass)
      u = self.by_uname_or_email(uname)
      u && (u.pass_match?(pass) ? u : nil)
    end

    def api_login(uname, pass, devic_id)
      u = login(uname, pass)
      return [nil, :unable_to_login] if u.nil? # error
      sess = u.sessions.find_or_initialize_by(:device_id => devic_id)
      sess.activate
    end

    def check_login_for(extuid_token)
      u = self.by_extid(extuid_token)
      return [nil, :user_not_found] if u.nil?
      true
    end

    def forgot_pass(email_or_uname)
      u = self.by_uname_or_email(email_or_uname)
      return [nil, :user_not_found] if u.nil?
      (u.password = rand_s) && u.hash_password
      (saved = u.my_save(true)) && AppMailer.forgot_pass_mail(u).deliver
      saved
    end

    def human_attribute_name(attr, opts = {})
      humanized_attrs = {
        :avatar_filename => 'Filename',
        :avatar_size     => 'File size',
        :avatar_content_type => 'File type'
      }
      humanized_attrs[attr.to_sym] || super
    end

    # list of all users who liked foto_id
    def liked_photo(foto_id, page = 1, lmt = 20)
      foto = Photo[foto_id]
      return [] if foto.nil?
      usr_ids = foto.likes.only(:user_id).collect(&:user_id)
      offst = (page.to_i - 1) * lmt
      self.where(:_id.in => usr_ids).skip(offst).limit(lmt)
    end

    def add_flag_for(usr_id, frm_usr_id)
      usr = self.where(:_id => usr_id).only(:user_flags_count).first
      return [nil, :user_not_found] if usr.nil?
      obj = usr.send(:user_flags).build :from_user_id => frm_usr_id
      obj.save ? usr.reload : [nil, obj.errors.full_messages]
    end

    def all_expert_ids
      self.unscoped.experts.collect(&:id)
    end
  end

  # Signup using FB/Twitter will not carry password. Also handle users
  # signin up more than once(when reinstalling the app) using FB/Twitter, gracefully.
  def api_signup
    resp = check_duplicate_signup
    return resp unless resp.nil?
    self.password ||= self.class.rand_s
    resp = my_save
    return resp if resp.is_a?(Array) # save failed
    check_friendships && send_welcome_mail!
    resp
  end

  def check_duplicate_signup
    return nil unless self.platform && self.extuid
    u = User.where(:platform => platform, :extuid => extuid).first
    u && [nil, :duplicate_signup]
  end

  def api_reset_pass(pass, npass, cpass)
    return [nil, :cur_pass_blank] if npass.blank?
    return [nil, :cur_pass_not_match] unless pass_match?(pass)
    return [nil, :pass_same_as_new_pass] if pass == npass
    return [nil, :pass_confirmation_mismatch] unless npass == cpass
    self.password = npass
    self.my_save(true)
  end

  def guest?
    self.username == 'guest'
  end

  def hash_password(pass = nil)
    self.salt ||= generate_rand
    pass ||= self.password
    Digest::SHA1.hexdigest(pass, self.salt)
  end

  def pass_match?(pass)
    self.hashed_password == self.hash_password(pass)
  end

  def avatar=(file)
    return nil if file.nil?
    return delete_avatar if file.blank? # remove profic pic
    @avatar = file.path # temp file path
    self.avatar_filename = file.original_filename.to_s
    self.avatar_content_type = file.content_type.to_s
    self.avatar_size = file.size.to_i
    self.avatar_dimension = get_geometry(file)
  end

  def delete_avatar
    delete_file if self.valid?
    self.avatar_filename = nil
    self.avatar_content_type = nil
    self.avatar_size = nil
    self.avatar_dimension = nil
    true
  end

  def avatar_url=(img_url)
    io = open(URI.parse(img_url))
    # define original_filename meth on io, dynamically
    def io.original_filename; base_uri.path.split('/').last; end
    self.avatar = (io.original_filename.blank? ? nil : io)
  rescue Exception => ex
    puts ex.message
    Rails.logger.info "Error while parsing avatar: #{ex.message}"
  ensure
    io.close
    @avatar_url = img_url
  end

  def path(style = :original)
    return def_avatar_path(style) unless has_avatar?
    fpath = FOTO_PATH.dup
    fpath.sub!(/:id/, self.id.to_s)
    fpath.sub!(/:style/, style.to_s)
    fpath.sub!(/:extension/, extension)
    fpath
  end

  def url(style = :original)
    pth = self.path(style)
    pth = File.exist?(pth) ? pth : self.path
    pth = pth.sub("#{Rails.root}/public", "")
    File.join(request_domain, pth)
  end

  def url_thumb
    url(:thumb)
  end

  def url_large
    url(:large)
  end

  def user_id
    self.id.to_s
  end

  def aspect_fit(frame_width, frame_height)
    image_width, image_height = self.avatar_dimension.split('x')
    ratio_frame = frame_width / frame_height
    ratio_image = image_width.to_f / image_height.to_f
    if ratio_image > ratio_frame
      image_width  = frame_width
      image_height = frame_width / ratio_image
    elsif image_height.to_i > frame_height
      image_width = frame_height * ratio_image
      image_height = frame_height
    end
    [image_width.to_i, image_height.to_i]
  end

  def delete_photo(foto_id)
    foto = self.photos.where(:_id => foto_id).first
    !foto.nil? && foto.destroy
  end

  def follow_user(usr_id)
    f = self.follows.new(:follower_id => usr_id)
    f.my_save(true)
  end

  def unfollow_friend(frn_id)
    f = self.follows.where(:follower_id => frn_id).first
    return [nil, :friendship_not_found] if f.nil?
    !f.destroy.nil?
  end

  def following?(usr)
    frnship = self.follows.where(:follower_id => usr.id).first
    !frnship.nil?
  end

  # to check if the user is a friend_of_current_user.
  def my_friend?
    return 'n/a' if me?
    current_user.following?(self)
  end

  # friends should be a array of hash with full_name, email, extuid, account_type
  def invite_all(frnds)
    results = frnds.collect do |hsh|
      invite = self.invites.build(hsh)
      invite.save || invite.error_resp
    end
    errors  = results.select { |res| res != true }
    errors.blank? || [nil, errors]
  end

  def invites_and_friends
    frnd_ids = self.friend_ids
    frnd_ids << self.id # consider the current_user as a friend
    all_usrs = User.where(:admin => false).to_a
    all_usrs.each do |usr|
      usr.invite_state = frnd_ids.include?(usr.id) ? "Friend" : "User"
    end
    self.invites.to_a + all_usrs
  end

  def friend_ids
    @follws ||= self.follows.to_a
    @follws.collect(&:follower_id)
  end

  def friends
    @follws ||= self.follows.to_a
    @frnds ||= User.where(:_id.in => @follws.collect(&:follower_id))
  end

  def followers
    @my_follwrs ||= Follow.where(:follower_id => self.id).to_a
    @fllwrs ||= User.where(:_id.in => @my_follwrs.collect(&:user_id))
  end

  def followers_count
    @followrs_count ||= Follow.where(:follower_id => self.id).count
  end

  # checks friendships of all frnds with the current_user(self)
  def populate_friendship_state(frnds)
    # hash map lookup is faster than array
    my_frnds = self.friends.only(:id).to_a.group_by(&:id)
    frnds.each do |f|
      next if f.id == self.id # nil, if current_user
      f.friendship_state = my_frnds.key?(f.id) ? "Yes" : "No"
    end
    frnds
  end

  def mentions_list(foto_id = nil)
    mlist  = self.friends.only(:id, :username, :full_name).to_a
    if (foto = Photo.where(:_id => foto_id).first)
      uids = foto.comments.only(:user_id).collect(&:user_id)
      unless uids.empty?
        mlist << User.where(:_id.in => uids).only(:id, :username, :full_name).to_a
      end
    end
    mlist.flatten.uniq(&:username)
  end

  # return realtime photos(only published) count.
  def photos_count
    @fotos_cnt ||= self.photos.count
  end

  def my_photos(page = 1, lmt = 20)
    offst = (page.to_i - 1) * lmt
    self.photos.only(:id, :data_filename).recent(lmt).offset(offst).to_a
  end

  def fav_photos(page = 1, lmt = 20)
    offst = (page.to_i - 1) * lmt
    foto_ids = self.fav_photo_ids
    return [] if foto_ids.empty?
    Photo.where(:_id.in => foto_ids).limit(lmt).offset(offst).desc(:created_at)
  end

  def my_fonts(page = 1, lmt = 20)
    offst = (page.to_i - 1) * lmt
    self.fonts.limit(lmt).offset(offst)
  end

  def my_fav_fonts(page = 1, lmt = 20)
    offst = (page.to_i - 1) * lmt
    fnt_ids = self.fav_font_ids
    return [] if fnt_ids.empty?
    Font.where(:_id.in => fnt_ids).limit(lmt).offset(offst).desc(:created_at)
  end

  # return count of favorite fonts
  def fonts_count
    self.fav_fonts_count
  end

  def photo_ids
    @photo_ids ||= self.photos.only(:id).collect(&:id)
  end

  # count of fonts tagged
  def my_fonts_count
    @my_fonts_count ||= self.fonts.count
  end

  def fav_photo_ids
    @fav_foto_ids ||= self.likes.only(:photo_id).collect(&:photo_id)
  end

  def fav_font_ids
    @fav_font_ids ||= self.fav_fonts.only(:font_id).collect(&:font_id)
  end

  def commented_photo_ids
    @commted_foto_ids ||= self.comments.only(:photo_id).collect(&:photo_id)
  end

  def notifications_count
    self.notifications.unread.count
  end

  def notifs_all_count
    @notifs_cnt ||= self.notifications.count
  end

  def my_updates(pge = 1, lmt = 20)
    offst  = (pge.to_i - 1) * lmt
    notifs = self.notifications.skip(offst).limit(lmt).to_a
    # mark these notifs as read
    Notification.where(:_id.in => notifs.collect(&:id), :unread => true).update_all(:unread => false)
    notifs
  end

  # updates on friend's activity, grouped by friend_id
  def network_updates
    frn_ids, tspan = [self.friend_ids, 1.week.ago]
    return [] if frn_ids.empty?

    opts = { :user_id.in => frn_ids, :created_at.gt => tspan }
    # filter out activity on current_user photos.
    foto_ids = self.photo_ids
    fnt_ids = Font.where(:photo_id.in => foto_ids).only(:id).collect(&:id)

    liks = Like.where(opts.merge(:photo_id.nin => foto_ids)).desc(:created_at).to_a
    ftgs = FontTag.where(opts.merge(:font_id.nin => fnt_ids)).desc(:created_at).to_a
    flls = Follow.where(opts.merge(:follower_id.ne => self.id)).desc(:created_at).to_a
    favs = FavFont.where(opts).desc(:created_at).to_a
    (liks + ftgs + flls + favs).sort_by(&:created_at).reverse
  end

private

  def generate_rand(length = 8)
    SecureRandom.base64(length)
  end

  def self.rand_s(length = 8)
    rand(36 ** length).to_s(36)
  end

  def set_hashed_password
    return true if password.blank?
    self.hashed_password = self.hash_password
  end

  def save_avatar_to_file
    return true if self.avatar.nil?
    ensure_dir(FOTO_DIR)
    ensure_dir(File.join(FOTO_DIR, self.id.to_s))
    Rails.logger.info "Saving file: #{self.path}"
    FileUtils.cp(self.avatar, self.path)
    true
  end

  def ensure_dir(dirname = nil)
    raise "directory path cannot be empty" if dirname.nil?
    unless File.exist?(dirname)
      FileUtils.mkdir(dirname)
    end
  end

  def delete_file
    return true unless has_avatar?
    Rails.logger.info "Deleting thumbnails.."
    remove_dir(File.join(FOTO_DIR, self.id.to_s))
    true
  end

  def remove_dir(dirname = nil)
    raise "directory path cannot be empty" if dirname.nil?
    if File.exist?(dirname)
      FileUtils.remove_dir(dirname, true)
    end
  end

  def save_thumbnail
    return true if self.avatar.nil?
    THUMBNAILS.each do |style, size|
      Rails.logger.info "Saving #{style.to_s}.."
      frame_w, frame_h = size.split('x')
      size = self.aspect_fit(frame_w.to_i, frame_h.to_i).join('x')
      `convert #{self.path} -resize '#{size}' -quality 75 -strip -unsharp 0.5x0.5+0.6+0.008 #{self.path(style)}`
    end
    true
  end

  def get_geometry(file)
    `identify -format %wx%h #{file.path}`.strip
  end

  # create friendships b/w all users invited me.
  def check_friendships
    invites = unless self.platform.blank? # FB/Twitter user
      Invite.where(:platform => self.platform, :extuid => self.extuid)
    else
      Invite.where(:email => self.email)
    end
    invites.to_a.each { |invit| invit.mark_as_friend(self) }

    # Also make fontli user as a mutual friend.
    fntli = User.fontli
    self.follows.create(:follower_id => fntli.id)
    fntli.follows.create(:follower_id => self.id)
    true
  end

  def send_welcome_mail!
    AppMailer.welcome_mail(self).deliver
  end
    
  def me?
    current_user.id.to_s == self.id.to_s
  end

  def has_avatar?
    !self.avatar_filename.blank?
  end

  def def_avatar_path(style = :original)
    DEFAULT_AVATAR_PATH.gsub(/:style/, style.to_s)
  end

  def extension
    File.extname(self.avatar_filename).gsub(/\.+/, '')
  end
end
