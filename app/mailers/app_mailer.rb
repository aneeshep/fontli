class AppMailer < ActionMailer::Base
  include Resque::Mailer # sent mails async

  default_url_options[:host] = APP_HOST_URL
  default from: "noreply@fontli.com"

  def welcome_mail(user)
    @user = user
    mail(:to => user['email'],
         :subject => "Welcome to Fontli")
  end

  def forgot_pass_mail(params)
    @params = params
    mail(:to => params['email'],
         :subject => "Fontli: New password")
  end

  def invite_mail(from_user, to_user)
    @user = to_user
    @from_user = from_user
    mail(:to => to_user.email,
         :subject => "Invitation to Fontli")
  end

  def share_photo_mail(opts = {})
    @message = opts.delete(:message)
    mail(opts)
  end

  def feedback_mail(feedbk)
    @feedbk = feedbk
    @user = feedbk.user
    mail(:to => 'info@fontli.com',
         :subject => "Feedback API - #{Rails.env}: #{feedbk.sugg_type}")
  end

  def flag_notif_mail(target)
    @target = target
    mail(:to => 'admin@fontli.com',
         :subject => "[#{Rails.env}] Suspension required")
  end
end
