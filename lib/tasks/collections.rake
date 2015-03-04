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
  task :import, [:csv_path] => :environment do |t, args|
    require 'csv'
    csv_path = args.csv_path || '/tmp/collections.csv'
    csv = CSV.readlines(csv_path)

    collection = nil
    csv[1..-1].each do |row|
      next if row[1].blank? # empty row

      collection_name = row[0].to_s.strip.downcase
      if collection_name.present?
        collection = Collection.where(name: collection_name).first_or_create
      end

      cover_photo_url = row[2].to_s.strip
      if cover_photo_url.present?
        cover_photo_id = Base64.decode64(cover_photo_url.split('/').last).gsub(/Photo_/, '')
        collection.update_attribute(:cover_photo_id, cover_photo_id)
      end

      photo_id = Base64.decode64(row[1].strip.split('/').last).gsub(/Photo_/, '')
      unless collection.photo_ids.include?(photo_id)
        collection.photo_ids << photo_id
        collection.save
      end
    end
    puts "Completed."
  end
end
