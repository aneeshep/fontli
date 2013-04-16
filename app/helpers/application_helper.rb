module ApplicationHelper
  def flash_notices
    cnt = "".html_safe
    [:notice, :alert].each do |k|
      cnt << content_tag(:div, flash[k], :id => k.to_s) if flash.key?(k)
    end
    cnt
  end

  def errors_for(obj)
    errs = obj.errors.collect do |k, v|
      k = '' if k == :base # don't add Base
      msg = k.to_s.humanize + ' ' + v
      content_tag(:li, msg)
    end.join.html_safe
    content_tag(:ul, errs, :id => 'errors') unless errs.blank?
  end

  # obj param can be model obj or obj.errors.full_messages array
  def simple_errors_for(obj_or_errs)
    return "" if obj_or_errs.blank?
    errs  = obj_or_errs.errors.full_messages if obj_or_errs.respond_to?(:errors)
    outpt = (errs || obj_or_errs).join('<br/>').html_safe
    content_tag(:div, outpt, :class => 'errors') unless outpt.blank?
  end
  
  def hidden_user_detail_tags(f)
    return "" if params[:platform] == 'default'
    cnt = f.hidden_field(:platform, :value => params[:platform])
    cnt << f.hidden_field(:extuid, :value => @user.extuid)
    cnt << f.hidden_field(:avatar_url,
                          :value => @user.avatar_url || @avatar_url)
    cnt
  end

  def signup_welcome_note
    return "" if params[:platform] == 'default'
    opts = { 
      :name   => @user.full_name,
      :avatar => @user.avatar_url || @avatar_url
    }
    note = content_tag(:p, "Hi #{opts[:name]}!", :class => 'username')
    note << content_tag(:span, 'Please complete the form below to register your account.')
    wel_note = "<img src='#{opts[:avatar]}' />".html_safe
    wel_note << content_tag(:div, note, :class => 'left')
    wel_note << "<p class='clear'></p>".html_safe
    content_tag(:div, wel_note, :class => 'welcome-note')
  end

  def timestamp(dattime)
    if (Time.now - dattime) < 5.minutes
      'Just now'
    else
      str = distance_of_time_in_words_to_now(dattime)
      # truncate almost/about or any kind of prefix
      str.gsub(/^[a-zA-Z]*\s/, '') + ' ago'
    end
  end

  def profile_image(usr=nil, size=:small)
    u = usr || @user || current_user
    src = size == :small ? u.url_thumb : u.url_large
    style = size == :small ? 'width:50px;height:50px' : 'width:inherit;height:inherit'
    content_tag(:img, nil, :src => src, :style => style)
  end

  def photo_details_li(foto=nil)
    foto ||= @photo

    lks = cmts = fnts = ''
    ts = content_tag(:span, timestamp(foto.created_at))

    if foto.likes_count > 0
      lks = content_tag(:a, pluralize(foto.likes_count, 'like'), :href => "javascript:;", :class => 'likes_cnt')
    end
    if foto.comments_count > 0
      cmts = content_tag(:a, pluralize(foto.comments_count, 'comment'), :href => "javascript:;", :class => 'comments_cnt')
    end
    if foto.fonts_count > 0
      fnts = content_tag(:a, pluralize(foto.fonts_count, 'font'), :href => "javascript:;", :class => 'fonts_cnt', 'data-url' => feed_fonts_path(:id => foto.id))
    end
    ts + lks + cmts + fnts
  end

  # returns {font_tag_id1 => #font1, font_tag_id2 => #font2, .. }
  def fonts_map_for_comments(cmts)
    fnt_tag_ids = cmts.collect(&:font_tag_ids).flatten.uniq
    fnt_tags = FontTag.where(:_id.in => fnt_tag_ids).only(:id,:font_id).to_a
    fnt_ids = fnt_tags.collect(&:font_id).uniq
    fnts_by_id = Font.where(:_id.in => fnt_ids).to_a.group_by(&:id)

    fnt_tags.inject({}) do |hsh, ft|
      hsh.update(ft.id => fnts_by_id[ft.font_id].first)
    end
  end

  # HACK: to NOT show any links for V1 launch
  def profile_path(opts)
    'javascript:;'
  end
end
