require 'ostruct'

# Acts as a cache layer for font details fetched from MyFonts
# Data here can change anytime and needs to refreshed every day
class FontDetail
  include Mongoid::Document
  include Mongoid::Timestamps

  field :family_id, :type => Integer
  field :name, :type => String
  field :url, :type => String # MyFonts URL
  field :desc, :type => String # article_abstract, can be empty
  field :owner, :type => String # publisher name

  index :family_id, :unique => true

  embeds_many :sub_font_details

  validates :family_id, :name, :url, :owner, :presence => true

  # assumes to be always successful, unless just leaves a message in the log.
  def self.ensure_create(details)
    fnt = self.find_or_initialize_by(:family_id => details[:id])
    status = fnt.update_attributes(
      :name => details[:name], :url => details[:url], :desc => details[:desc], :owner => details[:owner]
    )
    logger.fatal "FontDetail create failed for #{fnt.inspect}" unless status

    styles = details.delete(:styles) || []
    styles.each do |style|
      subfnt = fnt.sub_font_details.find_or_initialize_by(:style_id => style[:id])
      status = subfnt.update_attributes(:name => style[:name], :url => style[:url])
      logger.fatal "SubFontDetail create failed for #{subfnt.inspect}" unless status
    end
    true
  end

  def self.for(family_id, style_id = nil)
    fnt_detail = self.where(:family_id => family_id).first
    return fnt_detail if fnt_detail.nil? || style_id.blank?

    puts "error"
    subfnt = fnt_detail.subfont(style_id)
    subfnt && subfnt.to_obj
  end

  def image
    MyFontsApiClient.font_sample(self.family_id)
  end

  def subfont(style_id)
    self.sub_font_details.where(:style_id => style_id.to_i).first
  end
end
