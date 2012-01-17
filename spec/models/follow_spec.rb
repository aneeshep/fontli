require 'spec_helper'

describe Follow do
  it { should belong_to_related(:user)} #Have to check for index
  it { should belong_to_related(:follower).of_type(User)} #Have to check for index
  it { should validate_presence_of(:follower_id)}
  it { should validate_presence_of(:user_id)}
  
end