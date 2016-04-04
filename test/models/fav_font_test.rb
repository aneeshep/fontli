require 'test_helper'

describe FavFont do
  subject { FavFont }

  it { must belong_to(:user) }
  it { must have_index_for(:user_id) }
  it { must belong_to(:font) }
  it { must have_index_for(:font_id) }

  it { must validate_presence_of(:user_id) }
  it { must validate_presence_of(:font_id) }
  it { must validate_uniqueness_of(:user_id) }
end
