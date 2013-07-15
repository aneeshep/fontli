require 'font_family'

class FontsController < ApplicationController
  def tag_font
    # re-using the same method for apis
    @resp, @error = Photo.add_comment_for(
      :photo_id  => params[:photo_id],
      :user_id   => current_user.id,
      :font_tags => [params[:font]]
    )
    @photo = Photo[params[:photo_id]]
    @fonts = @photo.fonts.desc(:created_at).to_a
    render :layout => false
  end

  def font_autocomplete
    fonts = FontFamily.font_autocomplete(params[:term])
    render :json => fonts
  end

  def font_details
    @fonts = Rails.cache.fetch("font_details_#{params[:fontname]}") do
      FontFamily.font_details(params[:fontname])
    end
    render :layout => false
  end

  def sub_font_details
    @sub_fonts_list = cache("sub_font_details_#{params[:uniqueid]}") do
      FontFamily.sub_font_details(params[:uniqueid])
    end
    render :layout => false
  end
end
