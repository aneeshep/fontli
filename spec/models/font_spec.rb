require 'spec_helper'

describe Font do
  it { should belong_to_related(:photo)} #Have to check for index
  it { should belong_to_related(:user)} #Have to check for index
  it { should validate_presence_of(:name) }
  
  it { should have_fields(:name,:api_id,:coords).of_type(String)}
  
end