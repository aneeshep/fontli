namespace :photos do

  desc "Shift Photos from local machine to AWS S3"
  task :export_to_aws => :environment do
    AWS_API_CONFIG = YAML::load_file(File.join(Rails.root, 'config/aws_s3.yml'))[Rails.env].symbolize_keys
    AWS_BUCKET = AWS_API_CONFIG.delete(:bucket)
    AWS_STORAGE_CONNECTIVITY =  Fog::Storage.new(AWS_API_CONFIG)
    THUMBNAILS = { :large => '640x640', :medium => '320x320', :thumb => '150x150' }
    logger = Logger.new("#{Rails.root}/log/aws_storage.log")

    Photo.all.order("created_at asc").each do |photo|
      extension = File.extname(photo.data_filename).gsub(/\.+/, '')
      file_data = [:original] + THUMBNAILS.keys
      file_data.each do |filepath|
        if File::exists?(photo.path(filepath))
          file_obj = File.open(photo.path(filepath))
          AWS_STORAGE_CONNECTIVITY.directories.get(AWS_BUCKET).files.create(:key => photo.aws_path(filepath), :body => file_obj, :public => true, :content_type => extension)
        end
      end
      logger.info("Photo - #{photo.id} - moved to S3 at #{photo.created_at}")
    end
  end

  desc "Verify all thumbnails are available in S3 and are of correct dimensions"
  task :verify_thumbnails => :environment do
    Mongoid.logger = Logger.new(STDOUT)
    Mongoid.logger.level = Logger::ERROR
    aws_dir = Photo::AWS_STORAGE_CONNECTIVITY.directories.get(Photo::AWS_BUCKET)
    thumbs = Photo::THUMBNAILS
    missing, size_issues = {}, {}

    Photo.in_batches(1000) do |fotos|
      fotos.each do |f|
        foto_size = {}
        thumbs.each do |style, size|
          file = aws_dir.files.head(f.aws_path(style))
          foto_size[style] = 0

          if file
            foto_size[style] = file.content_length
          else
            missing[f.id.to_s] ||= []
            missing[f.id.to_s] << style
          end
        end # thumbs

        miss = missing[f.id.to_s]
        if foto_size[:large] < foto_size[:medium] && miss && !miss.include?(:large)
          size_issues[f.id.to_s] ||= []
          size_issues[f.id.to_s] << :large
        end

        if foto_size[:medium] < foto_size[:thumb] && miss && !miss.include?(:medium)
          size_issues[f.id.to_s] ||= []
          size_issues[f.id.to_s] << :medium
        end
      end # fotos
    end # batches

    puts missing.inspect
    puts "--------------"
    puts size_issues.inspect
  end
end
