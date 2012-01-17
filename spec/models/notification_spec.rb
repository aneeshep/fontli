require 'spec_helper'

describe Notification do
  it { should belong_to(:from_user).of_type(User)} #Have to check for index
  it { should belong_to(:to_user).of_type(User)} #Have to check for index
  it { should belong_to(:notifiable)}
  it { should validate_presence_of(:from_user_id) }
  it { should validate_presence_of(:to_user_id) }
  it { should validate_presence_of(:notifiable_id) }
  it { should validate_presence_of(:notifiable_type) }
  
  it { should have_field(:unread).of_type(Boolean).with_default_value_of(true) }
  
  before(:all) do
    @from_user = User.create!(:username => 'priya123', :full_name => "Priyadharsini", :email => "priyadharsini.nitt@gmail.com", :password => "pramati123", :avatar_filename => "priya.jpg")
    @to_user = User.create!(:username => 'priya12', :full_name => "PriyaBaskar", :email => "priyadharsininitt@gmail.com", :password => "pramati12", :avatar_filename => "priya1.jpg")
    @comment = Comment.create!(:username => @from_user.username, :body => "This is my first test comment.")
    @notification = Notification.create!(:from_user_id => @from_user.id, :to_user_id => @to_user.id, :notifiable_id => @comment.id, :notifiable_type => "Comment")
  end
  
  it "should return the notification message" do
    @notification.message == @from_user.full_name + " has commented your photo"
  end
end