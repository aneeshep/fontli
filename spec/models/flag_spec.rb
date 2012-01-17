require 'spec_helper'

describe Flag do
  it { should belong_to_related(:photo)} #Have to check for index
  it { should belong_to_related(:user)} #Have to check for index
  it { should validate_uniqueness_of(:user_id).scoped_to(:photo_id) }
  
end