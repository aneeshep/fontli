module AdminHelper

  def cta_req?
    @approve_sos || @suspend_user || @unflag_user || @unflag_photo || @activate_user
  end
end
