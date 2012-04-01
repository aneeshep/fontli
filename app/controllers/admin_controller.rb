class AdminController < ApplicationController

  skip_before_filter :login_required # skip the regular login check
  before_filter :admin_required # use http basic auth

  def index
    @users_count = User.count
    @fotos_count = Photo.count
  end

  def users
    @page, @lmt = [(params[:page] || 1).to_i, 10]
    offst       = (@page - 1) * @lmt
    unless params[:search].to_s.strip.blank?
      @users = User.search(params[:search])
    else
      @users = User.non_admins.desc(:points).skip(offst).limit(@lmt)
      @users_cnt = User.non_admins.count
      @max_page  = (@users_cnt / @lmt.to_f).ceil
    end
    @suspend_user = true
  end

  def suspend_user
    @res = User.where(:_id => params[:id]).first.update_attribute(:active, false)
    opts = @res ? {:notice => 'User account suspended.'} : {:alert => 'Couldn\'t suspend. Please try again!'}
    redirect_to '/admin/users', opts
  end

  def suspended_users
    @page, @lmt = [1, 10]
    @users = User.unscoped.where(:active => false).desc(:created_at).to_a
    @title, params[:search] = ['Suspended Users', 'Not Implemented']
    @activate_user = true
    render :users
  end

  def activate_user
    @res = User.unscoped.where(:_id => params[:id]).first.update_attribute(:active, true)
    opts = @res ? {:notice => 'User account activated.'} : {:alert => 'Couldn\'t activate. Please try again!'}
    redirect_to '/admin/users', opts
  end

  def photos
    @page, @lmt = [(params[:page] || 1).to_i, 10]
    offst = (@page - 1) * @lmt
    if !params[:search].to_s.strip.blank?
      @fotos = Photo.where(:caption => /^#{params[:search]}.*/i).to_a
    elsif !params[:user_id].to_s.strip.blank?
      @fotos = Photo.where(:user_id => params[:user_id]).desc(:likes_count).to_a
      params[:search] = 'Not Implemented'
    else
      @fotos = Photo.all.desc(:likes_count).skip(offst).limit(@lmt)
      @fotos_cnt = Photo.count
      @max_page  = (@fotos_cnt / @lmt.to_f).ceil
    end
    @delete_photo = true
  end

  def flagged_users
    @page, @lmt = [1, 10]
    @users = User.unscoped.where(:user_flags_count.gte => User::ALLOWED_FLAGS_COUNT).desc(:user_flags_count).to_a
    @title, params[:search] = ['Flagged Users', 'Not Implemented']
    @unflag_user = true
    render :users
  end

  def unflag_user
    @res = User.unscoped.where(:_id => params[:id]).first.user_flags.destroy_all
    opts = @res ? {:notice => 'User account unflagged.'} : {:alert => 'Couldn\'t unflag. Please try again!'}
    redirect_to '/admin/flagged_users', opts
  end

  def flagged_photos
    @page, @lmt = [1, 10]
    @fotos = Photo.unscoped.where(:flags_count.gte => Photo::ALLOWED_FLAGS_COUNT).desc(:flags_count).to_a
    @title, params[:search] = ['Flagged Photos', 'Not Implemented']
    @unflag_photo = true
    @delete_photo = true
    render :photos
  end

  def unflag_photo
    @res = Photo.unscoped.where(:_id => params[:id]).first.flags.destroy_all
    opts = @res ? {:notice => 'Photo has been unflagged.'} : {:alert => 'Couldn\'t unflag. Please try again!'}
    redirect_to '/admin/flagged_photos', opts
  end

  def sos
    @page, @lmt = [(params[:page] || 1).to_i, 10]
    offst = (@page - 1) * @lmt
    @title, conds = ['SoS photos', {:font_help => true}]
    if params[:req] == 'true'
      @title = 'SoS photos waiting for approval'
      conds = conds.merge(:sos_approved => false)
      @approve_sos = true
    end
    unless params[:search].to_s.strip.blank?
      conds = conds.merge(:caption => /^#{params[:search]}.*/i)
      @fotos = Photo.where(conds).to_a
    else
      @fotos = Photo.where(conds).desc(:created_at).skip(offst).limit(@lmt)
      @fotos_cnt = Photo.where(conds).count
      @max_page  = (@fotos_cnt / @lmt.to_f).ceil
    end
    @delete_photo = true
    render :photos
  end

  def approve_sos
    @res = Photo[params[:photo_id]].update_attribute(:sos_approved, true) rescue false
    opts = @res ? {:notice => 'SoS Approved.'} : {:alert => 'Couldn\'t approve. Please try again!'}
    redirect_to '/admin/sos', opts
  end

  def delete_photo
    @res = Photo.unscoped.where(:_id => params[:id]).destroy rescue false
    opts = @res ? {:notice => 'Photo deleted.'} : {:alert => 'Couldn\'t delete. Please try again!'}
    redirect_to '/admin/photos', opts
  end

end
