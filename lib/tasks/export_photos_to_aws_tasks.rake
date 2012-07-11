namespace :export_photos_to_aws do

  desc "Shift Photos from local machine to AWS S3"
  task :import_photos => :environment do
    AWS_API_CONFIG = YAML::load_file(File.join(Rails.root, 'config/aws_s3.yml'))[Rails.env].symbolize_keys
    AWS_BUCKET = AWS_API_CONFIG.delete(:bucket)
    AWS_STORAGE_CONNECTIVITY =  Fog::Storage.new(AWS_API_CONFIG)
    
    Photo.all.limit(5).each do |photo|
      file_data = [:original] + THUMBNAILS.keys
      file_data.each do |filepath|
        file_obj = File.open(photo.path(filepath))
        AWS_STORAGE_CONNECTIVITY.directories.get(AWS_BUCKET).files.create(:key => photo.aws_path(filepath), :body => file_obj, :public => true, :content_type => photo.extension)
      end
    end
  end

end
