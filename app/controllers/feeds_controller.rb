class FeedsController < ApplicationController
  def index
    @feeds = Photo.recent(10).includes(:comments)
    unless params[:photo_id].blank?
    @photo = current_user.photos.unpublished.find(params[:photo_id])
    @status = true
    end
  end

  def post_feed
    return if request.get?
    @photo = current_user.photos.unpublished.first
    @photo ||= current_user.photos.new(:caption => Photo::DEFAULT_TITLE)
    @photo.data = params[:photo]
    @status = @photo.save
    redirect_to :action => "index", :photo_id => @photo.id
  end

  def publish_feed
    return if request.get?
    @photo = current_user.photos.unpublished.find(params[:id])
    @photo.caption = params[:caption]
    @photo.crop = params[:crop]
    if @photo.save
    redirect_to feeds_url, :notice => "Posted to feed, successfully."
    end
  end
  
  def remove_unpublished_feed
    @photo = current_user.photos.unpublished.find(params[:photo_id])
    @photo.destroy
  end

  def socialize_feed
    return if request.get?
    @photo = Photo.find(params[:id])
    meth_name = "#{params[:modal]}_feed".to_sym
    self.method(meth_name).call
    render meth_name
  end

  def detail_view
    @foto = Photo.find(params[:id])
  end
  
  def get_mentions_list
    @foto = Photo.find(params[:id])
    @mentions_list = current_user.mentions_list(@foto.id)
  end

  private

  def like_feed
    lke = @photo.likes.new(:user_id => current_user.id)
    lke.save
  end

  def unlike_feed
    lke = @photo.likes.where(:user_id => current_user.id).first
    lke.destroy
  end

  def comment_feed
    @cmt = @photo.comments.new(
      :user_id => current_user.id,
      :body => params[:body]
    )
    @status = @cmt.save
  end

  def share_feed
  end

  def flag_feed
    flg = @photo.flags.new(:user_id => current_user.id)
    flg.save
  end

  def unflag_feed
    flg = @photo.flags.where(:user_id => current_user.id).first
    flg.destroy
  end

  def remove_feed
    @status = @photo.destroy
  end
end
