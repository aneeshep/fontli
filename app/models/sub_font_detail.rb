class SubFontDetail
  include Mongoid::Document
  include Mongoid::Timestamps

  field :style_id, :type => Integer
  field :name, :type => String
  field :url, :type => String # MyFonts URL

  embedded_in :font_detail

  validates :style_id, :name, :url, :presence => true

  after_save :fixup_font_family_id

  def image
    family_id = self.font_detail.family_id
    MyFontsApiClient.font_sample(family_id, self.style_id)
  end

  # form a openstruct combining font and subfont details
  def to_obj
    fnt_detail = self.font_detail
    @obj ||= OpenStruct.new(
      :name => self.name, :image => self.image, :url => self.url,
      :desc => fnt_detail.desc, :owner => fnt_detail.owner
    )
  end

private

  # every time a subfont is created/updated check if the Fonts collection
  # also has the same family_id for all fonts with this subfont_id
  def fixup_font_family_id
    family_id = self.font_detail.family_id
    scpe = Font.where(:subfont_id => self.style_id.to_s, :family_id.ne => family_id.to_s)
    affected_cnt = scpe.count
    return true if affected_cnt.zero?

    logger.fatal "fixup_font_family_id - Updating #{scpe.count} font records"
    scpe.update(:family_id => family_id)
  end
end
