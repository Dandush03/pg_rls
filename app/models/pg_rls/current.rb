# frozen_string_literal: true

module PgRls
  # Current Tenant State
  class Current < ::ActiveSupport::CurrentAttributes
    attribute(*PgRls.current_attributes.dup.push(:tenant, :tenant_history))

    PgRls.current_attributes.each do |attribute|
      define_method(attribute) do
        @attributes[attribute] ||= fetch_attribute(attribute)
      end
    end

    def fetch_attribute(attribute)
      klass_name = attribute.to_s.gsub("__", "/").classify

      send(:"#{attribute}=", klass_name.constantize.first)
    end

    def tenant=(tenant)
      add_tenant_to_history
      super
      tenant&.set_rls
    end

    def reset
      history = Array @attributes[:tenant_history]
      super
      @attributes[:tenant_history] = history
      restore_most_recent_tenant
      @attributes
    end

    private

    def add_tenant_to_history
      @attributes[:tenant_history] ||= []
      @attributes[:tenant_history] << @attributes[:tenant] unless @attributes[:tenant].nil?
    end

    def restore_most_recent_tenant
      @attributes[:tenant] = @attributes[:tenant_history].pop
      return PgRls::Tenant.reset_rls_used_connections if @attributes[:tenant].nil?

      @attributes[:tenant].set_rls
    end
  end
end
