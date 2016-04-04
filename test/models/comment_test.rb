require 'test_helper'

describe Comment do
  subject { Comment }

  it { must have_fields(:body).of_type(String) }
  it { must have_fields(:font_tag_ids, :foto_ids).of_type(Array) }

  it { must belong_to(:photo) }
  it { must have_index_for(:photo_id) }
  it { must belong_to(:user) }
  it { must have_index_for(:user_id) }

  it { must have_many(:mentions) }

  it { must validate_presence_of(:user_id) }
  it { must validate_presence_of(:photo_id) }
  it { must validate_length_of(:body).with_maximum(500) }
end
