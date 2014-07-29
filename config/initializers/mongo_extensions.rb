module MongoExtensions

  def current_user
    controller.current_user
  end

  def controller
    Thread.current[:current_controller]
  end

  # return current_time in UTC always
  def current_time
    Time.zone.now
  end

  def request_domain
    'http://' + controller.request.env['HTTP_HOST']
  end

  def generate_rand(length = 8)
    SecureRandom.base64(length)
  end

  def perma
    str = "#{self.class}_#{self.id.to_s}"
    str = Base64.urlsafe_encode64(str)
    CGI.escape(str)
  end

  def permalink
    request_domain + '/' + perma
  end

  def created_dt
    dt = self.created_at.utc.to_s(:api_format) if self.respond_to?(:created_at)
    dt || ""
  end

  def my_save(return_bool = false)
    saved = self.save
    saved ? (return_bool || self) : [nil, self.errors.full_messages]
  end

  # utility meth to return 'user' for #<User>
  def klass_s
    self.class.to_s.underscore
  end

  def klass_sym
    klass_s.to_sym
  end
end
