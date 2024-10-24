# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        # This module is responsible for changing the `create_table` method to `create_rls_table`
        # when the table is a RLS table.
        module SchemaDumper
          def tables(stream)
            tmp_stream = StringIO.new
            super(tmp_stream)

            stream_content = tmp_stream.string

            return stream.puts stream_content if @rls_tenant_table.nil?

            stream.puts @rls_tenant_table
            stream.puts unless stream_content.nil?
            stream.puts stream_content.chomp
          end

          def table(table_name, stream)
            original_table_method = method(:table).super_method
            stream_content = dump_table_to_string(original_table_method, table_name)

            if rls_tenant_table?(table_name)
              @rls_tenant_table = stream_content.gsub!("create_table", "create_rls_tenant_table").to_s
              return
            elsif rls_table?(table_name)
              stream_content.gsub!("create_table", "create_rls_table")
            end

            stream.print stream_content
          end

          private

          def dump_table_to_string(original_table_method, table_name)
            temp_stream = StringIO.new
            original_table_method.call(table_name, temp_stream)
            temp_stream.string
          end

          def rls_table?(table_name)
            rls_table_array.include?(table_name)
          end

          def rls_tenant_table?(table_name)
            PgRls.table_name.to_s == table_name.to_s
          end

          def rls_table_array
            @rls_table_array ||= fetch_rls_tables
          end

          def fetch_rls_tables
            statement = <<-SQL
              SELECT tablename FROM pg_policies WHERE schemaname = '#{PgRls.schema}';
            SQL
            @connection.execute(statement).to_a.map { |table| table["tablename"] }
          end
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.prepend(
  PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper
)
