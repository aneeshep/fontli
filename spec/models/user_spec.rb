require 'spec_helper'

describe User do
  it { should have_many(:photos).with_dependent(:destroy) }
  it { should have_many(:fonts).with_dependent(:destroy) }
  it { should have_many(:notifications).with_dependent(:destroy) }
  it { should have_many(:follows).with_dependent(:destroy) }
  it { should validate_presence_of(:username) }
  it { should validate_uniqueness_of(:username) }
  it { should validate_presence_of(:email) }
  it { should validate_uniqueness_of(:email)}
  it { should validate_presence_of(:password) }
  it { should validate_presence_of(:avatar_filename) }

  before do
    @user = User.new
  end

  it "should username length be minimum of 6 characters while signing up" do
    res = @user.save
    @user.errors[:username].should == ["can't be blank"]
  end

  it "should email valid while signing up" do
    @user.email = "123gmail.co.im.rsl"
    @user.save
    @user.errors[:email].should == ["is invalid"]
  end

  it "should password length be 8 characters while signing up" do
    @user.password = "123"
    @user.save
    @user.errors[:password].should == ["is too short (minimum is 8 characters)"]
  end

  #it "should validate while user signing up" do
  #  @user = User.new
  #  @user.save
  #  @user.should be_valid
  #end

  #it "should user to signup with their facebook/twitter account too" do
  #  @user = User.new(:extuid => "12345", :account_type => "Facebook")
  #  @user.save
  #  user = User[@user.username]
  #  user.id.should == @user.id
  #  user.account_type == "Facebook"
  #end

end