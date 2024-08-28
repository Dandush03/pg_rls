# frozen_string_literal: true

module PgRls
  # Current Context
  module Current
    class Context < ActiveSupport::CurrentAttributes
      attribute :tenant
    end
  end
end
