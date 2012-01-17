require 'font_family'

module FontsHelper
  include FontFamily
  def buy_at_href(font_id)
    font_detail = get_family_details(font_id) unless font_id.blank?
    return font_detail[:font_url], font_detail[:image]
  end
end
