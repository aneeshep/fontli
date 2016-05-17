namespace :users do
  desc "Update users photos_count"
  task :update_photos_count => :environment do
    start = Time.now.utc
    User.non_admins.includes(:photos).asc(:created_at).all.each { |u| u.update_attribute(:photos_count, u.photos.count)}
    puts "Completed in #{(Time.now.utc - start) / 60} mins."
    puts "Updated photos_count of #{User.non_admins.count} users."
  end
end
