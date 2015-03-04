namespace :collections do

  # rake collections:import[/tmp/collections.csv]
  #
  # CSV format:
  # ----------
  # collection_name, photo_url, cover_photo_url
  # nil, photo_url, nil
  # next_collection_name, photo_url, cover_photo_url
  #
  desc "Import new collections and their photos from a csv"
  task :import => :environment do |t, args|
    csv_path = args.first
    raise "Must specify csv file path as param" unless csv_path
    csv = CSV.readlines(csv_path)

    collection = nil
    csv[1..-1].each do |row|
      next if row[1].blank? # empty row

      collection_name = row[0].strip
      if collection_name.present?
        collection = Collection.find_or_create(name: collection_name)
      end

      cover_photo_url = row[2].strip
      if cover_photo_url.present?
        cover_photo_id = cover_photo_url.split('/').last
        collection.update_attribute(:cover_photo_id, cover_photo_id)
      end

      photo_id = row[1].strip.split('/').last
      unless collection.photo_ids.include?(photo_id)
        collection.photo_ids << photo_id
        collection.save
      end
    end
    puts "Completed."
  end
end
