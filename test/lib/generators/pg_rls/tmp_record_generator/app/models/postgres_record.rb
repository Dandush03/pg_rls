class PostgresRecord < PostgresRecord
  self.abstract_class = true

  connects_to database: { writing: :postgres }
end
