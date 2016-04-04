require 'test_helper'

describe FavWorkbook do
  subject { FavWorkbook }

  it { must belong_to(:user) }
  it { must have_index_for(:user_id) }
  it { must belong_to(:workbook) }

  it { must validate_presence_of(:user_id) }
  it { must validate_presence_of(:workbook_id) }
  it { must validate_uniqueness_of(:user_id) }
end
