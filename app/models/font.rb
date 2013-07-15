class Font
  include Mongoid::Document
  include Mongoid::Timestamps
  include MongoExtensions

  field :family_unique_id, :type => String
  field :family_name, :type => String
  field :family_id, :type => String
  field :subfont_name, :type => String
  field :subfont_id, :type => String
  field :agrees_count, :type => Integer, :default => 0
  field :font_tags_count, :type => Integer, :default => 0
  # pick_status is to identify expert/publisher's pick
  field :pick_status, :type => Integer, :default => 0
  field :expert_tagged, :type => Boolean, :default => false

  include MongoExtensions::CounterCache
  belongs_to :photo, :index => true
  belongs_to :user, :index => true
  has_many :agrees, :dependent => :destroy
  has_many :font_tags, :autosave => true, :dependent => :destroy
  has_many :fav_fonts, :dependent => :destroy
  has_many :hash_tags, :as => :hashable, :autosave => true, :dependent => :destroy

  validates :family_unique_id, :family_name, :family_id, :presence => true
  validates :photo_id, :user_id, :presence => true

  attr_accessor :img_url
  after_create :save_preview_image

  POPULAR_API_LIMIT = 20
  PICK_STATUS_MAP = { :expert_pick => 1, :publisher_pick => 2, :expert_publisher_pick => 3 }

  class << self
    def [](fnt_id)
      self.where(:_id => fnt_id).first
    end

    def add_agree_for(fnt_id, usr_id, cls_fnt_help = false)
      fnt = self[fnt_id]
      return [nil, :font_not_found] if fnt.nil?
      agr = fnt.agrees.build(:user_id => usr_id)
      saved = agr.my_save(true)
      saved = saved && fnt.photo.update_attribute(:font_help, false) if cls_fnt_help
      saved
    end

    def unagree_for(fnt_id, usr_id)
      fnt = self[fnt_id]
      return [nil, :font_not_found] if fnt.nil?
      agr = fnt.agrees.where(:user_id => usr_id).first
      return [nil, :record_not_found] if agr.nil?
      agr.destroy ? true : [nil, :unable_to_save]
    end

    def tagged_photos_for(opts, lmt = 20)
      page = opts.delete(:page) || 1
      fids = self.where(opts).only(:photo_id).to_a
      return [] if fids.empty?
      offst = (page.to_i - 1) * lmt
      Photo.where(:_id.in => fids.collect(&:photo_id)).desc(:created_at).skip(offst).limit(lmt)
    end

    # get popular family fonts(grouped) based on total tags_count, for a month
    # total tags_count, includes the count of subfonts as well.
    def cached_popular
      Rails.cache.fetch('popular_fonts', :expires_in => 2.days.seconds.to_i) do
        fnts = self.where(:created_at.gte => 1.months.ago).desc(:created_at).to_a
        resp = fnts.group_by { |f| f[:family_id] }
        resp = resp.sort_by { |fam_id, dup_fts| -dup_fts.sum(&:tags_count) }
        resp.collect { |fam_id, dup_fts| dup_fts.first }
      end
    end

    def popular
      lmt = POPULAR_API_LIMIT
      self.cached_popular.first(lmt)
    end

    # return no of popular fonts in random
    # assumes there are enough popular photos in DB
    def random_popular(lmt = 1)
      self.popular.shuffle.first(lmt)
    end

    # fonts with min 3 agrees or a publisher_pick, sorted by updated_at
    def api_recent
      lmt = POPULAR_API_LIMIT
      fnts = self.where(:agrees_count.gte => 3).to_a
      fnts += self.where(:pick_status.gte => PICK_STATUS_MAP[:publisher_pick]).to_a
      fnts = fnts.sort_by(&:updated_at).reverse
      return [] if fnts.empty?
      resp = fnts.group_by { |f| f[:family_id] }
      resp.collect { |fam_id, dup_fts| dup_fts.first }.first(lmt)
    end

    def search(name,sort = nil,dir = nil)
      return [] if name.blank?
      res = self.where(:family_name => /^#{name}.*/i).to_a
      res << self.where(:subfont_name => /^#{name}.*/i).to_a
      res = res.flatten.uniq(&:id)
      res = res.sort{|a,b| a.send(sort) <=> b.send(sort)} if sort
      res = res.reverse if dir == "asc"
      res
    end

    def search_autocomplete(name)
      return [] if name.blank?
      res = self.where(:family_name => /^#{name}.*/i).only(:family_name).collect(&:family_name)
      res + self.where(:subfont_name => /^#{name}.*/i).only(:subfont_name).collect(&:subfont_name)
    end
  end

  def tagged_photos_count
    @tagged_photos_count ||= Font.where(:family_id => self.family_id).count
  end

  def favs_count
    @favs_count ||= self.fav_fonts.count
  end

  def hashes=(hshs)
    return true if hshs.blank?
    hshs.each do |h|
      self.hash_tags.build(h)
    end
  end

  def tags_count
    self.font_tags_count
  end

  def heat_map
    tgs = self.font_tags.to_a
    tgs = tgs.group_by { |tg| tg.coords }
    tgs.collect do |coords, tgs_arr|
      x, y = coords.split(',')
      OpenStruct.new(:cx => x, :cy => y, :count => tgs_arr.length)
    end
  end

  def tagged_users
    cols = [:id, :data_filename, :username, :full_name]
    usrs = User.where(:_id.in => self.tagged_user_ids).only(*cols).to_a
    current_user.populate_friendship_state(usrs)
  end

  def tagged_user_ids
    @taggd_usr_ids ||= self.font_tags.only(:user_id).collect(&:user_id)
  end

  def recent_tagged_unames
    usr_ids = self.font_tags.desc(:created_at).limit(2).only(:user_id).collect(&:user_id)
    unames = [] if usr_ids.empty?
    unames ||= User.where(:_id.in => usr_ids).only(:username).collect(&:username)
  end

  # status of current_user with this font - Tagged or Agreed
  # cannot agree on a font, self tagged.
  def my_agree_status
    status = ''
    tagged = self.font_tags.where(:user_id => current_user.id).first
    if tagged.nil?
      agreed = self.agrees.where(:user_id => current_user.id).first
      status = 'Agreed' unless agreed.nil?
    else
      status = 'Tagged'
    end
    status
  end

  def my_fav?
    current_user.fav_font_ids.include? self.id
  end

  def img_url=(my_fnts_url)
    @img_url = my_fnts_url
  end

  def img_url
    request_domain + "/fonts/#{self.id.to_s}.png"
  end

  # Thumb url is set after font creation.
  # So its ok to create the image right here, if not created already.
  def thumb_url=(my_fnts_thumb_url)
    return true if my_fnts_thumb_url.blank?
    return true if my_fnts_thumb_url.to_s == '(null)'
    img_path = "public/fonts/#{self.id.to_s}_thumb.png"
    return true if File.exist? img_path
    Rails.logger.info "Creating thumb image for font - #{self.id.to_s}"
    io = open(URI.parse(my_fnts_thumb_url))
    `convert #{io.path} #{img_path}`
    true
  rescue Exception => ex
    Rails.logger.info "Error while saving font thumb image with url - #{my_fnts_thumb_url}: #{ex.message}"
    Airbrake.notify(ex)
    false
  ensure
    io && io.close
  end

  def thumb_url
    tpath = "/fonts/#{self.id.to_s}_thumb.png"
    tpath = '/font_thumb_missing.jpg' unless File.exist?('public' + tpath)
    request_domain + tpath
  end

  def display_name
    self.subfont_id.blank? ? self.family_name : self.subfont_name
  end

  def photo_ids
    [self.photo_id]
  end 

private

  def save_preview_image
    return true if @img_url.blank?
    img_path = "public/fonts/#{self.id.to_s}.png"
    io = open(URI.parse(@img_url))
    Rails.logger.info "Creating preview image for font - #{self.id.to_s}"
    `convert #{io.path} #{img_path}`
  rescue Exception => ex
    Rails.logger.info "Error while saving font preview image: #{ex.message}"
    Airbrake.notify(ex)
  ensure
    io && io.close
  end
end
