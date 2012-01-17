# Make Uniqueness validator to use the custom error message
# patch from https://github.com/jetheredge/mongoid/commit/a4f44ef232fc8acd907aa57f163039466852cfd9
module Mongoid
  module Validations

    class UniquenessValidator < ActiveModel::EachValidator

      def validate_each(document, attribute, value)
        if document.embedded?
          return if skip_validation?(document)
          relation = document._parent.send(document.metadata.name)
          criteria = relation.where(criterion(document, attribute, value))
        else
          criteria = klass.where(criterion(document, attribute, value))
        end
        criteria = scope(criteria, document, attribute)
        document.errors.add(attribute, :taken, { :message => options[:message] }) if criteria.exists?
      end

    end
  end
end

