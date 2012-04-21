# All fontli rake tasks
namespace :fontli do

  desc 'Update the font image_url from MyFonts, if changed'
  task :update_font_img_url => :environment do
    require 'font_family'

    fnts = Font.popular
    puts "Trying to update #{fnts.length} fonts.."
    updated_fnts_cnt = 0
    fnts.each do |f|
      dets = FontFamily.font_sample(f.family_id, f.family_name)
      puts("Sample Image not available for #{f.family_id}") || next if dets.blank?

      img_url = dets.match(/(.*)src=(.*)style=(.*)/) && $2.to_s.strip.gsub("\"", '')
      puts "Image url from API is empty!" if img_url.blank?
      #next if img_url == f.img_url
      f.update_attribute(:img_url, img_url) && updated_fnts_cnt += 1
    end
    puts "Done. Updated #{updated_fnts_cnt} font image urls."
  end

  desc 'Update the font thumb_url from MyFonts, if missing'
  task :update_font_thumb_url => :environment do
    Font.class_eval { def request_domain; ""; end } # avoid exceptions due to nil request
    require 'font_family'

    fnts = Font.all.to_a
    updated_fnts_cnt = 0
    fnts.each do |f|
      next unless f.thumb_url =~ /thumb_missing/
      dets = FontFamily.font_thumb(f.family_id)
      puts("Sample Image not available for #{f.family_id}") || next if dets.blank?

      thmb_url = dets.match(/(.*)src=(.*)style=(.*)/) && $2.to_s.strip.gsub("\"", '')
      puts "Thumb url from API is empty!" if thmb_url.blank?
      f.update_attribute(:thumb_url, thmb_url) && updated_fnts_cnt += 1
    end
    puts "Done. Updated #{updated_fnts_cnt} font thumb urls."
  end

  desc 'Display app statistics'
  task :stats => :environment do
    usr_cnt = User.count
    puts "#{usr_cnt} users"
    fotos_cnt = Photo.count
    puts "#{fotos_cnt} photos"
    fnts_cnt = Font.count
    puts "#{fnts_cnt} typefaces"
    cmts_cnt = Comment.count
    puts "#{cmts_cnt} comments"
  end

  desc 'Trigger email for all the suggestions and feedbacks stored in DB'
  task :email_feedbacks => :environment do
    suggs = Suggestion.unnotified.to_a
    puts "Trying to notify about #{suggs.length} feedbacks"
    success_cnt = 0
    suggs.each do |sg|
      begin
        AppMailer.feedback_mail(sg).deliver!
        sg.update_attribute(:notified, true) && (success_cnt += 1)
      rescue Exception => ex
        Airbrake.notify(ex)
      end
    end
    puts "Complete. Emailed #{success_cnt} feedbacks."
  end
end
