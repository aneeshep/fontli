namespace :export_photos_to_aws do

  desc "Shift Photos from local machine to AWS S3"
  task :export_photos => :environment do
    AWS_API_CONFIG = YAML::load_file(File.join(Rails.root, 'config/aws_s3.yml'))[Rails.env].symbolize_keys
    AWS_BUCKET = AWS_API_CONFIG.delete(:bucket)
    AWS_STORAGE_CONNECTIVITY =  Fog::Storage.new(AWS_API_CONFIG)
    THUMBNAILS = { :large => '640x640', :medium => '320x320', :thumb => '150x150' }

    Photo.all.limit(5).each do |photo|
      extension =     File.extname(photo.data_filename).gsub(/\.+/, '')
      file_data = [:original] + THUMBNAILS.keys
      file_data.each do |filepath|
        if File::exists?(photo.path(filepath))
          file_obj = File.open(photo.path(filepath))
          AWS_STORAGE_CONNECTIVITY.directories.get(AWS_BUCKET).files.create(:key => photo.aws_path(filepath), :body => file_obj, :public => true, :content_type => extension)
        end
      end
    end
  end

end
