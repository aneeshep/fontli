class StorifyStory
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :link, :type => String
  field :text, :type => String
  field :name, :type => String
  field :avatar, :type => String

  validates :text, :name, :avatar, :presence => true

  def self.random_story
    stories = self.all.to_a
    stories.at rand(stories.length)
  end
end
