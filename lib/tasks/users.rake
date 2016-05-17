namespace :users do
  desc "Update users photos_count"
  task :update_photos_count => :environment do
    start = Time.now.utc
    per_batch = 1000
    0.step(User.count, per_batch) do |offset|
      User.non_admins.asc(:created_at).skip(offset).limit(per_batch).each do |user|	
	user.update_attribute(:photos_count, user.photos.count)
      end
    end
    puts "Completed in #{(Time.now.utc - start) / 60} mins."
    puts "Updated photos_count of #{User.non_admins.count} users."
  end
end
