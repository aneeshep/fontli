require 'spec_helper'


describe Like do
  it { should belong_to(:user)} #Have to check for index
  it { should belong_to(:photo)} #Have to check for index
  it { should have_many(:notifications).with_dependent(:destroy)}
  it { should validate_uniqueness_of(:user_id).scoped_to(:photo_id) }
  
  before(:all) do
    @user = User.create(:username => 'priya123', :email => "priyadharsini.nitt@gmail.com", :password => "pramati123", :avatar_filename => "priya.jpg")
    @photo = Photo.create(:caption => "Diwali", :data_filename => "priya1.jpg")
    @like = Like.create(:user_id => @user.id, :photo_id => @photo.id)
  end
  
  it "should return the text - has liked" do
   @like.notif_context.include?("has liked")
  end

end