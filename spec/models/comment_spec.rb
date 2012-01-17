require 'spec_helper'

describe Comment do
  it { should belong_to(:photo)}
  it { should have_many(:notifications).with_dependent(:destroy) }
  it { should validate_presence_of(:body) }
  it { should validate_length_of(:body).with_maximum(120)}
  
  it { should have_fields(:body,:username).of_type(String)}
  
  before(:all) do
    @user = User.create!(:username => 'priya12344', :email => "nitt@gmail.com", :password => "pramati123", :avatar_filename => "priya.jpg")
    @user1 = User.create!(:username => 'priya1234', :email => "test@gmail.com", :password => "pramati12", :avatar_filename => "priya1.jpg")
    @comment = Comment.create(:username => @user.username, :body => "This is my first test comment.")
  end
  
  it "should return the user" do
    @comment.user.username == @user.username
    @comment.user.username != @user1.username
  end
  
  it "should return the text - has commented" do
   @comment.notif_context.include?("has commented")
  end
end