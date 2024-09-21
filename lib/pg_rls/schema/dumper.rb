module PgRls
  module Schema
    module Dumper
      def table(table, stream)
        temp_stream = StringIO.new
        super(table, temp_stream)
        temp_stream_string = temp_stream.string
        if rls_tenant_table?(table)
          temp_stream_string.gsub!('create_table', 'create_rls_tenant_table')
        elsif rls_table?(table)
          temp_stream_string.gsub!('create_table', 'create_rls_table')
        end

        stream.print(temp_stream_string)
      end

      private

      def rls_table?(table_name)
        # Logic to determine if the table uses RLS
        # You can check if the table has RLS policies or use a naming convention
        @connection.execute(<<-SQL).any?
          SELECT 1 FROM pg_policies WHERE tablename = #{ActiveRecord::Base.connection.quote(table_name)};
        SQL
      end

      def rls_tenant_table?(table_name)
        # Logic to determine if the table is a tenant table
        # You can check if the table has a specific column or use a naming convention
        PgRls.table_name.to_s == table_name
      end
    end
  end
end
