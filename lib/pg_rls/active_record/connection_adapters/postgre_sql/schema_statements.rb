# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        # This module contains the logic to create rls policies tables and functions
        module SchemaStatements
          def create_rls_tenant_table(table_name, ...)
            create_rls_initialize_setup
            create_table(table_name, ...)
            create_rls_tenant_table_setup(table_name)
          end

          def convert_to_rls_tenant_table(table_name)
            create_rls_initialize_setup
            create_rls_tenant_table_setup(table_name)
          end

          def create_rls_table(table_name, ...)
            create_table(table_name, ...)
            create_rls_table_setup(table_name) if check_rls_user_privileges!(PgRls.username, PgRls.schema)
          end

          def convert_to_rls_table(table_name)
            create_rls_table_setup(table_name) if check_rls_user_privileges!(PgRls.username, PgRls.schema)
          end

          def drop_rls_tenant_table(table_name, ...)
            drop_rls_initialize_setup(table_name)
            drop_table(table_name, ...)
          end

          def revert_from_rls_tenant_table(table_name)
            drop_rls_initialize_setup(table_name)
            remove_column(table_name, :tenant_id)
          end

          def drop_rls_table(table_name, ...)
            drop_rls_table_setup(table_name)
            drop_table(table_name, ...)
          end

          def revert_from_rls_table(table_name)
            drop_rls_table_setup(table_name)
          end

          {
            create_rls_tenant_table: :drop_rls_tenant_table,
            convert_to_rls_tenant_table: :revert_from_rls_tenant_table,
            create_rls_table: :drop_rls_table,
            convert_to_rls_table: :revert_from_rls_table
          }.each do |cmd, inv|
            [[inv, cmd], [cmd, inv]].uniq.each do |method, inverse|
              class_eval <<-RUBY, __FILE__, __LINE__ + 1
                def invert_#{method}(args, &block)          # def invert_create_table(args, &block)
                  [:#{inverse}, args, block]                #   [:drop_table, args, block]
                end                                         # end
              RUBY
            end
          end

          private

          def create_rls_table_setup(table_name)
            add_column(table_name, :tenant_id, :uuid, null: false) unless column_exists?(table_name, :tenant_id)
            enable_table_rls(table_name, PgRls.username)
            append_rls_table_triggers(table_name)
          end

          def create_rls_tenant_table_setup(table_name)
            unless column_exists?(table_name, :tenant_id)
              add_column(
                table_name, :tenant_id, :uuid, default: "gen_random_uuid()", null: false
              )
            end
            add_index(table_name, :tenant_id, unique: true) unless index_exists?(table_name, :tenant_id, unique: true)
            append_tenant_table_triggers(table_name)
          end

          def create_rls_initialize_setup
            create_rls_group
            create_rls_role(PgRls.username, PgRls.password)
            grant_rls_user_privileges(PgRls.schema)
            create_rls_functions
          end

          def drop_rls_table_setup(table_name)
            drop_rls_table_triggers(table_name)
            disable_table_rls(table_name, PgRls.username)
            remove_column(table_name, :tenant_id, if_exists: true) if table_exists?(table_name)
          end

          def drop_rls_initialize_setup(table_name)
            drop_tenant_table_triggers(table_name)
            drop_rls_functions
            revoke_rls_user_privileges(PgRls.schema)
            drop_rls_role(PgRls.username)
            drop_rls_group
          end
        end
      end
    end
  end
end
