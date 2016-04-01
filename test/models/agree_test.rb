require 'test_helper'

describe Agree do
  subject { Agree }

  it { must belong_to(:user) }
  it { must have_index_for(:user_id) }
  it { must belong_to(:font) }
  it { must have_index_for(:font_id) }

  describe 'callback' do
    let(:agree) { Agree.new }

    describe 'after_create' do
      it 'should inc_font_pick_status' do
      end
    end

    describe 'after_destroy' do
      it 'should dec_font_pick_status' do
      end
    end
  end
end
