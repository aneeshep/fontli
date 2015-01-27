class PopularCollection < Collection

  # memoized version of photos to be used in collection_detail api
  def fotos
    @fotos ||= Photo.popular
  end

  def photos_count
    self.fotos.count
  end

  # url of the first popular photo
  def cover_photo_url
    self.fotos.first.try(:url_large)
  end

  # cant follow dynamic collections
  def can_follow?
    false
  end
end
