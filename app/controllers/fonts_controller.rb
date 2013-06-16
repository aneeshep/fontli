require 'font_family'

class FontsController < ApplicationController
  def tag_font
    @photo = Photo.find(params[:photo_id])
    @font = @photo.fonts.new(params[:font])
    @font.user_id = current_user.id
    @font.save
    redirect_to :back
  end

  def fetch_font_families
    if params[:term]
      fonts = FontFamily.font_autocomplete(params[:term])
      render :json => fonts
    else
      redirect_to :root
    end
  end

  def get_font_details
    @fonts_list = FontFamily.font_details(params[:font_name]) unless params[:font_name].blank?
    render :layout => false
  end

  def get_sub_font_details
    @sub_fonts_list = FontFamily.sub_font_details(params[:uniqueid]) unless params[:uniqueid].blank?
    render :layout => false
  end
end
