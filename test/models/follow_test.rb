require 'test_helper'

describe Follow do
  subject { Follow }

  it { must belong_to(:user) }
  it { must belong_to(:follower) }

  it { must have_index_for(:user_id) }
  it { must have_index_for(:follower_id) }

  it { must validate_length_of(:user_id) }
  it { must validate_length_of(:follower_id) }
  it { must validate_uniqueness_of(:follower_id) }
end
