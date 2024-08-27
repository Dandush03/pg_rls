module PgRls
  module Current
    class Context < ActiveSupport::CurrentAttributes
      attribute :tenant
    end
  end
end
