# Use this only when the numericality is REALLY required.
module Mongoid
  module NumericIdentity

    module InstanceMethods

      def generate_identity
        id_attempt = (self.class.last.try(:id) || 0) + 1
        dup_check = self.class.where(:id => id_attempt).first
        if dup_check.nil?
          self.id = id_attempt
        else
          generate_identity
        end
      end

    end

    module ClassMethods

      def id(id)
        return any_in(:_id => id) if id.kind_of? Array
        return where(:_id => id)
      end

    end

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
      base.before_create :generate_identity
    end

  end
end
