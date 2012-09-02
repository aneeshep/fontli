class FavWorkbook
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include MongoExtensions

  belongs_to :user, :index => true
  belongs_to :workbook, :index => true

  validates :user_id, :workbook_id, :presence => true
  validates :user_id, :uniqueness => { :scope => :workbook_id, :message => "has already favorited!" }
end

