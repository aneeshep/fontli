#When db changes happens
namespace :db_changes do

  desc "Shift the data from photo id to hashable id For Change Column"
  tasks :hash_tags_data_change_from_photo_id_to_hashable_id => :environment do
    HashTag.all.each do |ht|
      ht.update_attributes(:hashable_id => ht.photo_id, :hashable_type => "Photo") unless ht.photo_id.blank?
    end
  end
end
