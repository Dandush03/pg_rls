# frozen_string_literal: true

# Row Level Security for PostgreSQL
module PgRls
  # Base class for all models that should be protected by RLS
  class Record < PgRls.abstract_base_record_class.constantize
    self.abstract_class = true

    self.ignored_columns += %w[tenant_id]

    connects_to(**PgRls.connects_to)
  end
end
