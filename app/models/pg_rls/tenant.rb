# frozen_string_literal: true

module PgRls
  # Tenant model
  class Tenant < Record
    include Securable
    include Switchable
  end
end
