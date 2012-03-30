class AdminController < ApplicationController

  skip_before_filter :login_required # skip the regular login check
  before_filter :admin_required # use http basic auth

  def index
    @users_count = User.count
    @fotos_count = Photo.count
  end

  def users
    @page, @lmt = [(params[:page] || 1).to_i, 5]
    offst       = (@page - 1) * @lmt
    @users_cnt  = User.non_admins.count
    @max_page   = (@users_cnt / @lmt.to_f).round
    unless params[:search].to_s.strip.blank?
      @users = User.search(params[:search])
    else
      @users = User.non_admins.desc(:points).skip(offst).limit(@lmt)
    end
  end

  def photos
    @page, @lmt = [(params[:page] || 1).to_i, 5]
    offst = (@page - 1) * @lmt
    @fotos_cnt = Photo.count
    @max_page  = (@fotos_cnt / @lmt.to_f).round
    @fotos = Photo.all.desc(:likes_count).skip(offst).limit(@lmt)
  end

end
