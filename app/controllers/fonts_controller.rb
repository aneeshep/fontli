require 'font_family'

class FontsController < ApplicationController
  def tag_font
    @photo = Photo.find(params[:photo_id])
    @font = @photo.fonts.new(params[:font])
    @font.user_id = current_user.id
    @font.save
    redirect_to :back
  end

  def font_autocomplete
    fonts = FontFamily.font_autocomplete(params[:term])
    render :json => fonts
  end

  def font_details
    @fonts_list = FontFamily.font_details(params[:fontname]) unless params[:fontname].blank?
    render :layout => false
  end

  def sub_font_details
    @sub_fonts_list = FontFamily.sub_font_details(params[:uniqueid]) unless params[:uniqueid].blank?
    render :layout => false
  end
end
