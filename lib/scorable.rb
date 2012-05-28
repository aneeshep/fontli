# triggers to update points on scorable events: photo_upload/follow_user/like/comment
# Note: Points explicity set as zero will be considered dynamic and the
# corresponding method within the model(ex., Agree#active_points) will be evalued to get the final points.
module Scorable

  POINTS_MAP = {
    :photo    => { :active => 10 },
    :like     => { :passive => 01 },
    :comment  => { :active => 05, :passive => 01 },
    :font_tag => { :active => 05, :passive => 01 },
    :follow   => { :active => 01, :passive => 02 },
    :agree    => { :active => 0, :passive => 0 },
    :share    => { :active => 5, :passive => 0 }
  }

  POINTS_USER_MAP = { :active => :scorable_source_user, :passive => :scorable_target_user }

  def self.included(klss)
    super
    klss.class_eval do
      after_create :add_user_points
      after_destroy :negate_user_points

      def scorable_source_user
        User.unscoped.where(:_id => self.user_id).first #unscoped bec. getting inactive users
        #self.user
      end

      def scorable_target_user
        User.unscoped.where(:_id => self.photo.user_id).first #unscoped bec. getting inactive users
        #self.photo.user
      end
    end
  end

private

  def add_user_points
    update_user_points(:add)
  end

  def negate_user_points
    update_user_points(:negate)
  end

  # adds/subracts points to users(both direct n indirect)
  # ex., users gain points for commenting and being commented.
  def update_user_points(meth = :add)
    [:active, :passive].each do |kinda|
      pts = current_action_points(kinda)
      next unless pts
      pts = self.send((kinda.to_s + '_points').to_sym) if pts.zero? # dynamic points
      next unless pts > 0 # no update
      usr = self.send(credit_user(kinda))
      val = usr.points
      val = (meth == :add ? (val + pts) : (val - pts))
      usr.update_attribute(:points, val)
    end
    true
  end

  def current_action_points(kinda)
    action = self.klass_sym
    Scorable::POINTS_MAP[action][kinda]
  end

  def credit_user(kinda)
    Scorable::POINTS_USER_MAP[kinda]
  end
end
