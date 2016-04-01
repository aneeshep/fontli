require 'test_helper'

describe Collection do
  let(:collection)        { create(:collection) }
  let(:active_collection) { create(:collection, active: true) }
  let(:user)              { create(:user) }
  let(:photo)             { create(:photo) }

  subject { Collection }

  it { must have_fields(:name, :description, :cover_photo_id).of_type(String) }
  it { must have_fields(:active).of_type(Boolean).with_default_value(false) }

  it { must belong_to(:user) }
  it { must have_and_belong_to_many(:photos) }

  it { must validate_presence_of(:name) }
  it { must validate_uniqueness_of(:name) }
  it { must validate_length_of(:name).with_maximum(100) }
  it { must validate_length_of(:description).with_maximum(500) }

  describe '.active' do
    it 'should return active collection' do
      Collection.active.must_include active_collection
    end

    it 'should not return inactive collection' do
      Collection.active.wont_include collection
    end
  end

  describe '.[]' do
    it 'should find a collection with provided id' do
      Collection[collection.id].must_equal collection
    end

    it 'should not find a collection other than the provided id' do
      Collection[collection.id].wont_equal active_collection
    end
  end

  describe '.search' do
    it 'should return a collection with provided name' do
      Collection.search(collection.name).must_include collection
    end

    it 'should not return a collection other than the provided name' do
      Collection.search(active_collection.name).wont_include collection
    end
  end

  describe '#fotos' do
    let(:photo) { create(:photo) }

    before do
      collection.photos << photo
    end

    it 'should return collection photos' do
      collection.fotos.must_include photo
    end
  end

  describe '#photos_count' do
    before do
      collection.photos << photo
    end

    it 'should return the collection photos count' do
      collection.photos_count.must_equal 1
    end
  end

  describe '#can_follow?' do
    it 'should return true if current user can follow the collection' do
      collection.can_follow?.must_equal true
    end
  end

  describe '#custom?' do
    let(:collection1) { create(:collection, user: user) }

    it 'should return true if user_id present' do
      collection1.custom?.must_equal true
    end

    it 'should return false if user_id not present' do
      collection.custom?.must_equal false
    end
  end
end
