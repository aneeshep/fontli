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
    if (Time.now - dattime) < 15.minutes
      'Just now'
    else
      distance_of_time_in_words_to_now(dattime) + ' ago'
    end
  end
end
