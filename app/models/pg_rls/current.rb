# frozen_string_literal: true

module PgRls
  # Current Tenant State
  class Current < ::ActiveSupport::CurrentAttributes
    attribute(*PgRls.current_attributes.dup.push(:tenant))

    PgRls.current_attributes.each do |attribute|
      define_method(attribute) do
        @attributes[attribute] ||= fetch_attribute(attribute)
      end
    end

    def fetch_attribute(attribute)
      klass_name = attribute.to_s.gsub("__", "/").classify

      send(:"#{attribute}=", klass_name.constantize.first)
    end
  end
end
