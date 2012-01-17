# All fontli rake tasks
namespace :fontli do

  desc 'Update the font image_url from MyFonts, if changed'
  task :update_font_img_url => :environment do
    require 'font_family'
    include FontFamily

    fnts = Font.popular
    puts "Trying to update #{fnts.length} fonts.."
    updated_fnts_cnt = 0
    fnts.each do |f|
      dets = get_family_details(f.family_id)
      puts("Details not available for #{f.family_id}") || next if dets.blank?

      img_url = dets[:image].match(/(.*)src=(.*)style=(.*)/) && $2.to_s.strip.gsub("\"", '')
      puts "Image url is empty" if img_url.blank?
      next if img_url == f.img_url
      f.update_attribute(:img_url, img_url) && updated_fnts_cnt += 1
    end
    puts "Done. Updated #{updated_fnts_cnt} font image urls."
  end

end
