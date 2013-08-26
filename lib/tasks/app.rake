# All fontli rake tasks
namespace :fontli do
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

  desc 'Data Export based on created at'
  task :export_data => :environment do
    Font.class_eval { def request_domain; ""; end } # avoid exceptions due to nil request
    file = File.new("data_import.json", "w")
    file_info = File.new("data_export.info", "w")
    file_info.write "Process Started...\n"

    ["User", "Photo", "Font", "FontTag", "Comment", "HashTag", "Agree", "Follow", "FavFont", "Invite", "Mention"].each do |model_class|
  #    file.write "{\"#{model_class}\" :" + model_class.constantize.all.to_json + "}"
      file.write "{\"#{model_class}\":" + model_class.constantize.where(:created_at.gt => '2012-05-30 03:42:00').to_json + "}"
      file.write "\n"
      file_info.write "#{model_class.constantize.where(:created_at.gt => '2012-05-30 03:42:00').count} #{model_class.humanize} added \n"
    end
    file.close
    file_info.write "Data exported to data_import.json"
    file_info.close
  end
  
  desc 'Data Import based on Created at'
  task :import_data => :environment do
    file = File.open("data_import.json")
    file_info = File.new("data_import.info", "w")
    content = {}

    file_info.write "Process Started ...\n"
    file.each do |line|
      content = content.merge(JSON.parse(line))
    end

    id_map = {}
    content.each do |model,data|
      file_info.write "------------------------------------------\n"
      file_info.write "Importing #{model} -- Count #{data.length} \n"
      id_map = id_map.merge({model => {} }) unless id_map.keys.include?(model)

      data.each do |content_hash|
        obj = model.constantize.where(:_id => content_hash["_id"]).first
        content_id = content_hash["_id"]
        content_hash.delete("_id") if obj #Remove if id alredy available

        if model == "User"
          usr_obj = User.where(:username => content_hash["username"]).first
          usr_obj ||= User.where(:email => content_hash["email"]).first
          if usr_obj
            file_info.write "User obj already available #{usr_obj.email} | #{usr_obj.username} \n"
            id_map[model][content_id] = usr_obj.id 
            next
          end
        end

        content_hash.each do |key,value|
          if ["photo_id", "user_id", "font_id", "font_tag_id"].include?(key)
            content_hash[key] = id_map[key.split('_').first.camelize][value] if id_map[key.split('_').first.camelize][value]
          elsif ["mentionable_id"].include?(key)
            mention_type = content_hash["mentionable_type"]
            content_hash[key] = id_map[mention_type][value] if id_map[mention_type][value]
          elsif ["follower_id"].include?(key)
            content_hash[key] = id_map["User"][value] if id_map["User"][value]
          end
        end

        new_obj = model.constantize.new(content_hash) 
        invalid = !new_obj.valid?
        file_info.write "#{model} - #{content_hash['_id']} data is invalid #{new_obj.errors.full_messages.join(',')} \n" if invalid
        next if invalid && model != "User"

        begin
          new_obj.save(:validate => false)
        rescue Exception => ex
          Airbrake.notify ex
        end
        id_map[model][content_id] = new_obj.id.to_s if obj
      end
    end
    file_info.write "ID MAP : ---> #{id_map}"
    file_info.close
  end 
  
end
