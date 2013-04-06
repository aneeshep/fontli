class FeedsController < ApplicationController
  skip_before_filter :login_required, :only => [:show, :fonts]

  def index
    @photos = Photo.feeds_for(current_user, (params[:page] || 1)).to_a
    preload_photos_my_likes_comments
  end

  def show
    @photo = Photo[params['id']]
    preload_photo_associations
    render 'show', :layout => false
  end

  def sos
    @photos = Photo.sos(params[:page] || 1).to_a
    preload_photos_my_likes_comments
  end

  def fonts
    @fonts = Photo[params[:id]].fonts.to_a
    render :partial => 'spotted_pop', :layout => false
  end

  def recent_fonts
    @fonts = Font.api_recent
  end

  def profile
    params[:username] = nil if params[:username] == 'You'
    @user = if !params[:user_id].blank?
              User.by_id(params[:user_id])
            elsif !params[:username].blank?
              User[params[:username]]
            else
              current_user
            end
    page = params[:page] || 1

    case params[:type]
    when 'like'
      @photos = @user.fav_photos(page, 18)
      preload_photos_my_likes_comments(:skip_likes => true)
    when 'fav_font'
      @fonts = @user.fav_fonts(page, 18)
      #preload_fonts_photos # this is more tricky
    else
      offset = (page.to_i - 1) * 18
      @photos = @user.photos.recent(18).offset(offset)
      preload_photos_my_likes_comments
    end
  end

  def popular
    case params[:type]
    when 'post'
      @photos = Photo.popular
      preload_photos_my_likes_comments
    when 'font'
      @fonts = Font.popular.to_a
    else
      @users = User.new.recommended_users
      @friend_ids = current_user.friend_ids.group_by {|a| a}
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
    @photo.created_at = Time.now.utc
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

  # loads recent 5 likes and 5 comments with associated users for a foto.
  def preload_photo_associations(foto = nil)
    foto ||= @photo
    @recent_likes = foto.likes.desc(:created_at).limit(5).to_a
    lkd_usr_ids = @recent_likes.collect(&:user_id)
    @recent_comments = foto.comments.desc(:created_at).limit(5).to_a
    cmt_usr_ids = @recent_comments.collect(&:user_id)
    
    unless (lkd_usr_ids + cmt_usr_ids).empty?
      usrs = User.where(:_id.in => (lkd_usr_ids + cmt_usr_ids)).only(:id, :username, :avatar_filename).to_a
      @users_map = usrs.group_by(&:id)
    end
  end

  def preload_photos_my_likes_comments(opts={})
    f_ids, user = @photos.collect(&:id), @user || current_user
    if f_ids.any?
      @users_map = User.where(:_id.in => @photos.collect(&:user_id)).group_by(&:id)
      unless opts[:skip_likes]
        @my_lks = user.likes.where(:photo_id.in => f_ids).desc(:created_at).group_by(&:photo_id)
      end
      @my_cmts = user.comments.where(:photo_id.in => f_ids).desc(:created_at).group_by(&:photo_id)
    end
  end
end
