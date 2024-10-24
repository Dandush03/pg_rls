# frozen_string_literal: true

module PgRls
  # Base class for all models that should be protected by RLS
  class Record < ::ActiveRecord::Base
    self.abstract_class = true

    connects_to(**PgRls.connects_to)
  end
end
