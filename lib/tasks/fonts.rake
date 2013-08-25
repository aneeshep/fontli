namespace :fonts do
  desc "Fetches font details from MyFonts and stores it locally for all tagged fonts"
  task :build_details_cache => :environment do
    Mongoid.logger = Logger.new(STDOUT)
    Mongoid.logger.level = Logger::ERROR
    family_details_cache = {}

    fnts = Font.where(:subfont_id => '').only(:family_id)
    family_ids = fnts.collect(&:family_id)
    fnts = Font.where(:subfont_id => nil).only(:family_id)
    family_ids += fnts.collect(&:family_id)
    family_ids = family_ids.uniq
    total_cnt = family_ids.length
    puts "Building details for #{total_cnt} family fonts..."

    # record the current run timestamp, at the earliest
    Stat.current.update_attribute(:font_details_cached_at, Time.now.utc)

    family_ids.each_with_index do |fid, i|
      details = family_details_cache[fid]
      unless details
        details = MyFontsApiClient.font_details(fid)
        family_details_cache[fid] = details
      end

      FontDetail.ensure_create details.merge(:styles => [])
      if (i > 0) && (i % 50).zero?
        puts "Completed #{i+1}/#{total_cnt} family fonts."
      end
    end

    subfnts = Font.where(:subfont_id.ne => '').only(:subfont_id)
    style_ids = subfnts.collect(&:subfont_id).compact
    subfnts = Font.where(:subfont_id.ne => nil).only(:subfont_id)
    style_ids += subfnts.collect(&:subfont_id)
    style_ids = style_ids.delete_if { |sid| sid.blank? }.uniq
    total_cnt = style_ids.length
    puts "Building details for #{total_cnt} sub-fonts..."

    style_ids.each_with_index do |fid, i|
      details = MyFontsApiClient.subfont_details(nil, fid)

      FontDetail.ensure_create(details)
      if (i % 50).zero?
        puts "Completed #{i+1}/#{total_cnt} sub-fonts."
      end
    end

    puts "\nDone."
  end
end
