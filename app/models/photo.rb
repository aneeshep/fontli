class Photo
  include Mongoid::Document
  include MongoExtensions
  include Scorable

  field :caption, :type => String
  field :data_filename, :type => String
  field :data_content_type, :type => String
  field :data_size, :type => Integer
  field :data_dimension, :type => String
  field :latitude, :type => Float
  field :longitude, :type => Float
  field :address, :type => String
  field :font_help, :type => Boolean, :default => false
  field :likes_count, :type => Integer, :default => 0
  field :comments_count, :type => Integer, :default => 0
  field :flags_count, :type => Integer, :default => 0
  field :fonts_count, :type => Integer, :default => 0
  field :created_at, :type => Time

  include MongoExtensions::CounterCache
  belongs_to :user, :index => true
  has_many :fonts, :autosave => true, :dependent => :destroy
  has_many :likes, :dependent => :destroy
  has_many :flags, :dependent => :destroy
  has_many :shares, :dependent => :destroy
  has_many :comments, :autosave => true, :dependent => :destroy
  has_many :mentions, :as => :mentionable, :autosave => true, :dependent => :destroy
  has_many :hash_tags, :autosave => true, :dependent => :destroy

  FOTO_DIR = File.join(Rails.root, 'public/photos')
  FOTO_PATH = File.join(FOTO_DIR, ':id/:style.:extension')
  ALLOWED_TYPES = ['image/jpg', 'image/jpeg', 'image/png']
  DEFAULT_TITLE = 'Yet to publish'
  THUMBNAILS = { :large => '320x320', :thumb => '150x150' }
  POPULAR_LIMIT = 20

  validates :caption, :length => 2..500, :allow_blank => true
  validates :data_filename, :presence => true
  validates :data_size, 
    :inclusion => { :in => 0..(5.megabytes), :message => "should be less than 5MB" }, 
    :allow_blank => true
  validates :data_content_type, 
    :inclusion => { :in => ALLOWED_TYPES, :message => 'should be jpg/png' }, 
    :allow_blank => true

  attr_accessor :data, :crop_x, :crop_y, :crop_w, :crop_h, :from_api, :liked_user, :commented_user

  default_scope where(:caption.ne => DEFAULT_TITLE) # never show them in UI, except publish
  scope :recent, lambda { |cnt| desc(:created_at).limit(cnt) }
  scope :unpublished, where(:caption => DEFAULT_TITLE)
  scope :geo_tagged, where(:latitude.ne => 0, :longitude.ne => 0)
  scope :all_popular, Proc.new { where(:likes_count.gt => 1, :created_at.gt => 48.hours.ago).desc(:likes_count) }

  before_save :crop_file
  after_create :populate_mentions
  after_save :save_data_to_file, :save_thumbnail
  after_destroy :delete_file

  class << self
    def [](foto_id)
      self.where(:_id => foto_id.to_s).first
    end

    def human_attribute_name(attr, opts = {})
      humanized_attrs = {
        :data_filename => 'Filename',
        :data_size     => 'File size',
        :data_content_type => 'File type'
      }
      humanized_attrs[attr.to_sym] || super
    end

    def save_data(opts = {})
      def_opts = { :caption => DEFAULT_TITLE, :from_api => true }
      opts = def_opts.update opts
      foto = self.unpublished.where(:user_id => opts[:user_id]).first
      # just update the data, where there's one - unpublished
      unless foto.nil?
        foto.update_attributes(opts) if opts[:data]
        return foto
      end
      Rails.logger.info "Foto created at #{Time.now.utc} --#{`date`}--#{Time.zone.now}- with options - #{opts[:user_id].inspect}"
      self.new(opts).my_save
    end

    def publish(opts)
      foto = self.unpublished.where(:_id => opts.delete(:photo_id)).first
      return [nil, :photo_not_found] if foto.nil?
      opts[:created_at] = Time.now.utc
      resp = foto.update_attributes(opts)
      resp ? foto : [nil, foto.errors.full_messages]
    end

    def add_like_for(photo_id, usr_id)
      opts = { :user_id => usr_id }
      self.add_interaction_for(photo_id, :likes, opts)
    end

    def unlike_for(photo_id, usr_id)
      foto = self[photo_id]
      return [nil, :photo_not_found] if foto.nil?
      lk = foto.likes.where(:user_id => usr_id).first
      return [nil, :record_not_found] if lk.nil?
      lk.destroy ? foto.reload : [nil, :unable_to_save]
    end

    def add_flag_for(photo_id, usr_id)
      opts = { :user_id => usr_id }
      self.add_interaction_for(photo_id, :flags, opts)
    end

    def add_share_for(photo_id, usr_id)
      opts = { :user_id => usr_id, :return_bool => true }
      self.add_interaction_for(photo_id, :shares, opts)
    end

    # opts - photo_id, body, user_id, font_tags
    # creates the font_tags on the photo and then create the comment
    def add_comment_for(opts)
      foto = self[opts.delete(:photo_id)]
      return [nil, :photo_not_found] if foto.nil?
      ftags = opts.delete(:font_tags) || []
      # group by unique fonts
      ftags = ftags.group_by { |f| f[:family_unique_id] + f[:family_id] + f[:subfont_id].to_s }
      fnt, valid_font = [nil, true]
      opts[:font_tag_ids] = ftags.collect do |key, fnts|
        f, coords = [ fnts.first, fnts.collect { |hsh| hsh[:coords] } ]
        f[:user_id] = opts[:user_id]
        fnt, tag_ids = build_font_tags(f, foto, coords)
        break unless valid_font = (fnt.new_record? || fnt.save)
        tag_ids
      end.flatten
      return [nil, fnt.errors.full_messages] unless valid_font

      foto.comments.build(opts)
      foto.save ? foto.reload : [nil, foto.errors.full_messages]
    end

    def duplicate_like?
      !self.likes.where(:user_id => current_user.id).first.nil?
    end

    def duplicate_flag?
      !self.flags.where(:user_id => current_user.id).first.nil?
    end

    def feeds_for(usr = nil, page = 1, lmt = 15)
      usr ||= current_user
      frn_ids = usr.friend_ids + [usr.id]
      offst = (page.to_i - 1) * lmt
      Photo.where(:user_id.in => frn_ids).desc(:created_at).skip(offst).limit(lmt)
    end

    def popular
      pops = self.all_popular.limit(POPULAR_LIMIT * 3).to_a
      pops = pops.shuffle.slice(0, POPULAR_LIMIT)
      # add recent fotos if there aren't enough populars
      if pops.length < POPULAR_LIMIT
        pops += self.recent(POPULAR_LIMIT - pops.length)
      end
      pops
    end

    def all_by_hash_tag(tag_name, pge = 1, lmt = 20)
      return [] if tag_name.blank?
      hsh_tags = HashTag.where(:name => tag_name).only(:photo_id)
      foto_ids = hsh_tags.to_a.collect(&:photo_id)
      offst = (pge.to_i - 1) * lmt
      self.where(:_id.in => foto_ids).only(:id, :data_filename).skip(offst).limit(lmt).to_a
    end

    def sos(pge = 1, lmt = 20)
      return [] if pge.to_i > 5
      offst = (pge.to_i - 1) * lmt
      self.where(:font_help => true).desc(:created_at).skip(offst).limit(lmt).to_a
    end

    def check_mentions_in(val)
      regex = /\s@([a-zA-Z0-9]+\.?_?-?\$?[a-zA-Z0-9]+\b)/
      val = ' ' + val.to_s # add a space infront, to match mentions at the start.
      unames = val.to_s.scan(regex).flatten
      return [] if unames.blank?
      # return only valid users hash of id, username
      urs = User.where(:username.in => unames).only(:id, :username).to_a
      urs.collect { |u| { :user_id => u.id, :username => u.username } }
    end
  end

  def data=(file)
    return nil if file.blank?
    @data = file.path # temp file path
    self.data_filename = file.original_filename.to_s
    self.data_content_type = file.content_type.to_s
    self.data_size = file.size.to_i
    self.data_dimension = get_geometry(file)
  end

  def path(style =  :original)
    fpath = FOTO_PATH.dup
    fpath.sub!(/:id/, self.id.to_s)
    fpath.sub!(/:style/, style.to_s)
    fpath.sub!(/:extension/, extension)
    fpath
  end

  # returns original url, if thumb/large doesn't exist
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

  def crop?
    !crop_x.blank? && !crop_y.blank? && !crop_w.blank? && !crop_h.blank?
  end

  def crop=(crop_opts)
    crop_opts.each do |k, v|
      self.send("#{k.to_s}=".to_sym, v)
    end
  end

  # just build the fonts collection to ensure that
  # we don't create duplicates on validation failures.
  # fnts - Array of font hashes
  def font_tags=(fnts)
    return true if fnts.blank?
    fnts = fnts.group_by { |f| f[:family_unique_id] + f[:family_id] + f[:subfont_id].to_s }
    cur_user_id = current_user.id
    fnt_tag_ids = []
    fnts.each do |key, fonts|
      f, coords = [ fonts.first, fonts.collect { |hsh| hsh[:coords] } ]
      f[:user_id] = cur_user_id
      fnt, tag_ids = self.class.send(:build_font_tags, f, self, coords)
      fnt_tag_ids << tag_ids
    end
    # all font tags are also a comment
    self.comments.build(:user_id => cur_user_id, :font_tag_ids => fnt_tag_ids.flatten)
  end

  #hshs - Array of HashTag hashes
  def hashes=(hshs)
    return true if hshs.blank?
    hshs.each do |h|
      self.hash_tags.build(h)
    end
  end

  def aspect_fit(frame_width, frame_height)
    image_width, image_height = self.data_dimension.split('x')
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

  def username
    @usr ||= self.user
    @usr.username
  end

  def user_url_thumb
    @usr ||= self.user
    @usr.url_thumb
  end

  def top_fonts
    top_picks = self.fonts.where(:pick_status.gt => 0).to_a
    top_agreed = self.fonts.where(:agrees_count.gt => 10).to_a
    top_picks + top_agreed
  end

  # order fonts by top; pick_status -> agrees_count -> tags_count
  def fonts_ord
    fnts = self.fonts.to_a
    fnts.sort_by {|f| [-f.pick_status, -f.agrees_count, -f.tags_count] }
  end

  def liked?
    current_user.fav_photo_ids.include?(self.id)
  end

  def commented?
    current_user.commented_photo_ids.include?(self.id)
  end

  # populate last 5/2 two usernames who liked/commented on this foto.
  def populate_liked_commented_users(opts = {})
    lkd_usr_ids = [] if opts[:only_comments]
    cmt_usr_ids = [] if opts[:only_likes]
    lkd_usr_ids ||= self.likes.desc(:created_at).limit(5).only(:user_id).collect(&:user_id)
    cur_usr_id = lkd_usr_ids.delete(current_user.id)
    cmt_usr_ids ||= self.comments.desc(:created_at).limit(2).only(:user_id).collect(&:user_id)
    unless (lkd_usr_ids + cmt_usr_ids).empty?
      usrs = User.where(:_id.in => lkd_usr_ids + cmt_usr_ids).only(:id, :username).to_a
      usrs = usrs.group_by(&:id)
      self.liked_user = (cur_usr_id.nil? ? '' : 'You||') + lkd_usr_ids.collect { |uid| usrs[uid].first.username }.join('||')
      self.commented_user = cmt_usr_ids.collect { |uid| usrs[uid].first.username }.join('||')
    end
  end

private

  def self.add_interaction_for(photo_id, klass, opts = {} )
    photo = self[photo_id]
    return [nil, :photo_not_found] if photo.nil?
    obj = photo.send(klass.to_sym).build(opts)
    obj.save ? (opts[:return_bool] || photo.reload) : [nil, obj.errors.full_messages]
  end

  def self.build_font_tags(opts, foto, coords)
    find_opts = opts.dup.keep_if { |k, v| [:family_unique_id, :family_id, :subfont_id].include? k.to_sym }
    fnt = foto.fonts.find_or_initialize_by(find_opts)
    okeys = opts.keys - find_opts.keys - ['coords']
    okeys.each { |k| fnt.send("#{k}=".to_sym, opts[k]) }
    tag_ids = coords.collect do |c|
      tg = fnt.font_tags.build(:coords => c, :user_id => opts[:user_id])
      tg.id
    end
    [fnt, tag_ids]
  end

  def populate_mentions
    mnts = Photo.check_mentions_in(self.caption)
    mnts.each { |hsh| self.mentions.create(hsh) }
    true
  end

  def save_data_to_file
    return true if self.data.nil?
    ensure_dir(FOTO_DIR)
    ensure_dir(File.join(FOTO_DIR, self.id.to_s))
    Rails.logger.info "Saving file: #{self.path}"
    FileUtils.cp(self.data, self.path)
    true
  end

  def delete_file
    Rails.logger.info "Deleting thumbnails.."
    remove_dir(File.join(FOTO_DIR, self.id.to_s))
    true
  end

  def ensure_dir(dirname = nil)
    raise "directory path cannot be empty" if dirname.nil?
    unless File.exist?(dirname)
      FileUtils.mkdir(dirname)
    end
  end

  def remove_dir(dirname = nil)
    raise "directory path cannot be empty" if dirname.nil?
    if File.exist?(dirname)
      FileUtils.remove_dir(dirname, true)
    end
  end

  def get_geometry(file = nil)
    `identify -format %wx%h #{file.nil? ? self.path : file.path}`.strip
  end

  def crop_file
    return true unless crop?
    `convert #{self.path} -crop '#{crop_w.to_i}x#{crop_h.to_i}+#{crop_x.to_i}+#{crop_y.to_i}' #{self.path}`
    # update the dimension after cropping
    self.data_dimension = get_geometry
  end

  def save_thumbnail
    return true if self.data.nil?
    THUMBNAILS.each do |style, size|
      Rails.logger.info "Saving #{style.to_s}.."
      frame_w, frame_h = size.split('x')
      size = self.aspect_fit(frame_w.to_i, frame_h.to_i).join('x')
      `convert #{self.path} -resize '#{size}' -quality 95 -strip #{self.path(style)}`
    end
    true
  end

  def extension
    File.extname(self.data_filename).gsub(/\.+/, '')
  end
end
