namespace :export_photos_to_aws do

  desc "Shift Photos from local machine to AWS S3"
  task :import_photos => :environment do
    Photo.all.limit(5).each do |photo|
      photo.save_data_to_aws
    end
  end

end
