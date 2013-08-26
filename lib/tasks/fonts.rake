namespace :fonts do
  desc "Fetches font details from MyFonts and stores it locally for all tagged fonts"
  task :build_details_cache => :environment do
    logger = Logger.new('font_details_cache_report.rb')
    # record the current run timestamp, at the earliest
    Stat.current.update_attribute(:font_details_cached_at, Time.now.utc)

    # Build subfonts first as we can fix some the missing family_ids, during the run.
    subfnts = Font.where(:subfont_id.ne => '').only(:subfont_id)
    style_ids = subfnts.collect(&:subfont_id).compact
    subfnts = Font.where(:subfont_id.ne => nil).only(:subfont_id)
    style_ids += subfnts.collect(&:subfont_id)
    style_ids = style_ids.delete_if { |sid| sid.blank? }.uniq
    total_cnt = style_ids.length
    puts "Building details for #{total_cnt} sub-fonts..."
    missing_fnts = []

    style_ids.each_with_index do |fid, i|
      handle_myfonts_api_limit
      details = MyFontsApiClient.subfont_details(nil, fid)
      missing_fnts << fid if details.blank?
      FontDetail.ensure_create(details)

      if (i % 50).zero?
        puts "Completed #{i+1}/#{total_cnt} sub-fonts."
      end
    end
    puts "NOTE: Can't find details for #{missing_fnts.length} sub fonts. Run fixup"
    logger.info "@missing_subfonts = #{missing_fnts}"


    # Build Family Fonts
    fnts = Font.where(:subfont_id => '').only(:family_id)
    family_ids = fnts.collect(&:family_id)
    fnts = Font.where(:subfont_id => nil).only(:family_id)
    family_ids += fnts.collect(&:family_id)
    family_ids = family_ids.uniq
    total_cnt = family_ids.length
    puts "Building details for #{total_cnt} family fonts..."
    missing_fnts = []

    family_ids.each_with_index do |fid, i|
      handle_myfonts_api_limit
      details = MyFontsApiClient.font_details(fid)
      missing_fnts << fid if details.blank?
      FontDetail.ensure_create details.merge(:styles => [])

      if (i > 0) && (i % 50).zero?
        puts "Completed #{i+1}/#{total_cnt} family fonts."
      end
    end
    puts "NOTE: Can't find details for #{missing_fnts.length} family fonts. Run fixup"
    logger.info "@missing_fonts = #{missing_fnts}"

    puts "\nDone."
  end

  desc "Fixup missing fonts by finding them based on the names"
  task :fixup_missing => :environment do
    # TODO: Complete this
    #
    Stat.current.update_attribute(:font_fixup_missing_ran_at, Time.now.utc)
  end

  # Check if we have crossed the hourly limit. If so, sleep for an hour
  def handle_myfonts_api_limit
    return if can_access_myfonts?

    puts "Sleeping for an hour...zzzzzz"
    sleep(3660) # a minute buffer
    puts "Time to continue..."
  end
end
