require 'test_helper'

describe Agree do
  let(:user)   { create(:user, expert: true) }
  let(:photo)  { create(:photo, sos_requested_by: user.id) }
  let(:font)   { create(:font, photo: photo) }
  let(:agree)  { create(:agree, user: user, font: font) }
  let(:agree1) { create(:agree) }

  subject { Agree }

  it { must belong_to(:user) }
  it { must have_index_for(:user_id) }
  it { must belong_to(:font) }
  it { must have_index_for(:font_id) }

  it { must validate_presence_of(:user_id) }
  it { must validate_presence_of(:font_id) }
  it { must validate_uniqueness_of(:user_id) }

  describe '#publisher_pick?' do
    it 'should return true' do
      agree.publisher_pick?.must_equal true
    end

    it 'should return false' do
      agree1.publisher_pick?.must_equal false
    end
  end

  describe '#sos_requestor_pick?' do
    it 'should return true' do
      agree.sos_requestor_pick?.must_equal true
    end

    it 'should return false' do
      agree1.sos_requestor_pick?.must_equal false
    end
  end

  describe '#expert_pick?' do
    it 'should return true' do
      agree.expert_pick?.must_equal true
    end

    it 'should return false' do
      agree1.expert_pick?.must_equal false
    end
  end
end
