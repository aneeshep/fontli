module MongoExtensions
  def current_user
    FactoryGirl.create(:user)
  end
end
