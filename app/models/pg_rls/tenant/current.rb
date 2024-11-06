# frozen_string_literal: true

module PgRls
  class Tenant
    # Current Tenant State
    class Current < ::ActiveSupport::CurrentAttributes
      attribute :session
    end
  end
end
