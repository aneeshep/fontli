# API methods. Hit /doc for details.
class ApiActionsController < ApiBaseController

  def signin
    token, error = User.api_login(@username, @password, @device_id)
    reset_current_user_and_session # reset to use the new token
    render_response(token, !token.nil?, error)
  end

  def signup
    user, error = User.new(current_api_accepts_map).api_signup
    render_response(user, !user.nil?, error)
  end

  def signout
    resp, error = @extuid_token.nil? ? @current_session.deactivate : true
    render_response(resp, !resp.nil?, error)
  end

  def forgot_pass
    resp, error = User.forgot_pass(@email_or_uname)
    render_response(resp, !resp.nil?, error)
  end

  def reset_pass
    resp, error = @current_user.api_reset_pass(@password, @new_password, @confirm_password)
    render_response(resp, !resp.nil?, error)
  end

  def login_check
    resp, error = User.check_login_for(@extuid_token)
    render_response(resp, !resp.nil?, error)
  end

  def check_token
    resp = current_session && current_session.active?
    render_response(resp == true)
  end

  def upload_data
    resp, error = Photo.save_data(current_api_accepts_map_with_user)
    render_response(resp, !resp.nil?, error)
  end

  def publish_photo
    resp, error = Photo.publish(current_api_accepts_map)
    render_response(resp, !resp.nil?, error)
  end

  def photo_detail
    foto = Photo.where(:_id => @photo_id).first
    foto && foto.populate_liked_commented_users
    render_response(foto, !foto.nil?, :photo_not_found)
  end

  def update_photo
    resp, error = @current_user.update_photo(current_api_accepts_map)
    render_response(resp, !resp.nil?, error)
  end

  def delete_photo
    resp = @current_user.delete_photo(@photo_id)
    render_response(resp)
  end

  def like_photo
    photo, error = Photo.add_like_for(@photo_id, @current_user.id)
    render_response(photo, !photo.nil?, error)
  end

  def unlike_photo
    photo, error = Photo.unlike_for(@photo_id, @current_user.id)
    render_response(photo, !photo.nil?, error)
  end

  def flag_photo
    photo, error = Photo.add_flag_for(@photo_id, @current_user.id)
    render_response(photo, !photo.nil?, error)
  end

  def flag_user
    usr, error = User.add_flag_for(@user_id, @current_user.id)
    render_response(usr, !usr.nil?, error)
  end

  def share_photo
    resp, error = Photo.add_share_for(@photo_id, @current_user.id)
    render_response(resp, !resp.nil?, error)
  end

  def comment_photo
    photo, error = Photo.add_comment_for current_api_accepts_map_with_user
    commnts = photo && photo.comments.asc(:created_at).to_a
    render_response(commnts, !photo.nil?, error)
  end

  def comments_list
    foto = Photo[@photo_id]
    commnts = foto.nil? ? [] : foto.comments.asc(:created_at).to_a
    render_response(commnts)
  end

  def delete_comment
    cmt = Comment[@comment_id]
    resp = !cmt.nil? && cmt.destroy
    render_response(resp)
  end

  def agree_font
    clse_fnt_help = (@close_help.to_s == 'true')
    resp, error = Font.add_agree_for(@font_id, @current_user.id, clse_fnt_help)
    render_response(resp, !resp.nil?, error)
  end

  def unagree_font
    resp, error = Font.unagree_for(@font_id, @current_user.id)
    render_response(resp, !resp.nil?, error)
  end

  def fav_font
    fnt = Font[@font_id]
    @font_id = nil if fnt.nil? # hack to avoid invalid fonts
    fav = @current_user.fav_fonts.build(:font_id => @font_id)
    resp, error = fav.my_save(true)
    fnt && (fnt.thumb_url = @thumb_url) # update thumb_url
    render_response(resp, !resp.nil?, error)
  end

  def unfav_font
    fav = @current_user.fav_fonts.where(:font_id => @font_id)
    resp, error = [fav.destroy, :unable_to_save]
    render_response(resp, resp, error)
  end

  def likes_list
    usrs = User.liked_photo(@photo_id, @page || 1).to_a
    usrs = @current_user.populate_friendship_state(usrs)
    render_response(usrs)
  end

  def mentions_list
    mentions = @current_user.mentions_list(@photo_id)
    render_response(mentions)
  end

  def hash_tag_search
    hsh_tags = HashTag.search(@name)
    render_response(hsh_tags)
  end

  def hash_tag_photos
    photos = Photo.all_by_hash_tag(@name, @page || 1)
    render_response(photos)
  end

  def leaderboard
    users = User.leaders.to_a
    users = @current_user.populate_friendship_state(users)
    render_response(users)
  end

  def popular_photos
    photos = Photo.popular
    render_response(photos)
  end

  def sos_photos
    fotos = Photo.sos(@page || 1)
    render_response(fotos)
  end

  def popular_fonts
    fonts = Font.popular.to_a
    render_response(fonts)
  end

  def recent_fonts
    fonts = Font.api_recent
    render_response(fonts)
  end

  def font_photos
    opts = current_api_accepts_map
    fotos = Font.tagged_photos_for(opts)
    render_response(fotos.to_a)
  end

  def font_heat_map
    fnt = Font.where(:_id => @font_id).first
    render_response(fnt, !fnt.nil?, :record_not_found)
  end

  def user_search
    usrs = User.search(@name)
    usrs = @current_user.populate_friendship_state(usrs)
    render_response(usrs)
  end

  # find the profile either by id/username
  def user_profile
    usr = nil
    if @user_id
      usr = User.where(:_id => @user_id).first
    elsif @username
      usr = User.where(:username => @username).first
    else
      usr = @current_user
    end
    render_response(usr, !usr.nil?, :user_not_found)
  end

  def update_profile
    attrs = current_api_valid_accepts_map
    if attrs.keys.include?(:iphone_token)
      attrs[:iphone_token_updated_at] = Time.zone.now
    end
    resp = @current_user.update_attributes(attrs)
    render_response(resp, resp, @current_user.errors.full_messages)
  end

  def invite_friends
    resp, error = @current_user.invite_all(@friends)
    render_response(resp, !resp.nil?, error)
  end

  def my_invites
    invites = @current_user.invites_and_friends
    render_response(invites)
  end

  def user_friends
    usr = @user_id ? User.by_id(@user_id) : @current_user
    offst = ((@page || 1).to_i - 1) * 20
    frnds = usr.friends.skip(offst).limit(20).to_a
    frnds = @current_user.populate_friendship_state(frnds)
    render_response(frnds)
  end

  def user_followers
    usr = @user_id ? User.by_id(@user_id) : @current_user
    offst = ((@page || 1).to_i - 1) * 20
    fllwrs = usr.followers.skip(offst).limit(20).to_a
    fllwrs = @current_user.populate_friendship_state(fllwrs)
    render_response(fllwrs)
  end

  def user_photos
    usr = @user_id ? User.by_id(@user_id) : @current_user
    photos = usr.my_photos(@page || 1)
    render_response(photos)
  end

  def user_favorites
    usr = @user_id ? User.by_id(@user_id) : @current_user
    photos = usr.fav_photos(@page || 1).to_a
    render_response(photos)
  end

  def user_fonts
    usr = @user_id ? User.by_id(@user_id) : @current_user
    fonts = usr.my_fonts(@page || 1).to_a
    render_response(fonts)
  end

  def user_fav_fonts
    usr = @user_id ? User.by_id(@user_id) : @current_user
    fonts = usr.my_fav_fonts(@page || 1).to_a
    render_response(fonts)
  end

  def follow_user
    resp, error = @current_user.follow_user(@user_id)
    render_response(resp, !resp.nil?, error)
  end

  def unfollow_friend
    resp, error = @current_user.unfollow_friend(@friend_id)
    render_response(resp, !resp.nil?, error)
  end

  def add_suggestion
    sugg = Suggestion.new current_api_accepts_map_with_user
    resp, error = sugg.my_save
    render_response(resp, !resp.nil?, error)
  end

  def feeds_html
    @feeds = Photo.recent(10).to_a
    render 'feeds'
  end

  def my_notifications_count
    usr = @current_user
    render_response(usr)
  end

  def my_updates
    @page ||= 1
    @notifications = @current_user.my_updates(@page)
  end

  def network_updates
    updts = @current_user.network_updates
    @updates_by_user = updts.group_by(&:user_id)
    # updates grouped by item takes precedence over the individuals. Ex, abc and def liked photo1.
    @updates_by_item = updts.group_by { |u| u.klass_sym }
    return if updts.empty?

    # preload datasets for usernames, photo#url_large and font#family_name, img_url
    lik_foto_ids = (@updates_by_item[:like] || []).collect(&:photo_id)
    tag_fnt_ids = (@updates_by_item[:font_tag] || []).collect(&:font_id)
    tag_fotos = Font.where(:_id.in => tag_fnt_ids).only(:id, :photo_id).to_a
    @tags_map = tag_fotos.group_by(&:id)
    tag_foto_ids = tag_fotos.collect(&:photo_id)
    @photos_map = Photo.where(:_id.in => lik_foto_ids + tag_foto_ids).only(:id, :data_filename).group_by(&:id)
    fav_fnt_ids = (@updates_by_item[:fav_font] || []).collect(&:font_id)
    @fonts_map = Font.where(:_id.in => fav_fnt_ids).only(:id, :family_name, :family_id, :family_unique_id, :subfont_id, :subfont_name, :img_url).group_by(&:id)
    usr_ids = @updates_by_user.keys + (@updates_by_item[:follow] || []).collect(&:follower_id)
    @users_map = User.where(:_id.in => usr_ids).only(:id, :username, :avatar_filename).group_by(&:id)
  end

  # One damn costly api action in terms of DB queries.
  # Returns photos + flag to know whether the current_user liked/commented on it,
  # And also the username of the one who liked/commented on it.
  def my_feeds
    photos = Photo.feeds_for(@current_user, (@page || 1)).to_a
    return render_response([]) if photos.empty?
    foto_ids = photos.collect(&:id)

    foto_lks = Like.where(:photo_id.in => foto_ids).desc(:created_at).to_a
    foto_cmts = Comment.where(:photo_id.in => foto_ids).desc(:created_at).to_a

    usr_ids = (foto_lks.collect(&:user_id) + foto_cmts.collect(&:user_id))
    usr_ids = usr_ids.flatten.uniq
    usrs_map = [] if usr_ids.empty?
    usrs_map ||= User.where(:_id.in => usr_ids).only(:id, :username).to_a

    # generate #Hash's for faster lookup
    foto_lks = foto_lks.group_by(&:photo_id)
    foto_cmts = foto_cmts.group_by(&:photo_id)
    usrs_map = usrs_map.group_by(&:id)

    # populate 'liked_user' and 'commented_user' flags
    photos.each do |p|
      lks, cmts = [ foto_lks[p.id], foto_cmts[p.id] ]
      # get the last two usernames(seperated by ||) who liked/commented on the photo
      p.liked_user =  lks[0..1].collect { |l| usrs_map[l.user_id].first.username }.join('||') unless lks.nil?
      p.commented_user = cmts[0..1].collect { |c| usrs_map[c.user_id].first.username }.join('||') unless cmts.nil?
    end
    render_response(photos)
  end

  def feed_detail
    foto = Photo.where(:_id => @feed_id).first
    foto && foto.populate_liked_commented_users
    render_response(foto, !foto.nil?, :photo_not_found)
  end
end
