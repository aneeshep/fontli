class Mention
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include MongoExtensions
  include Notifiable

  field :username, :type => String

  belongs_to :mentionable, :polymorphic => true, :index => true
  belongs_to :user, :index => true

  validates :user_id, :username, :mentionable_id, :mentionable_type, :presence => true

  def notif_source_user_id
    self.mentionable.user_id
  end

  def notif_target_user_id
    self.user_id
  end
  
  def notif_context
    ['has mentioned']
  end
end
