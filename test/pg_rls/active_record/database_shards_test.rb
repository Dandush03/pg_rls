# frozen_string_literal: true

require "test_helper"

module PgRls
  module ActiveRecord
    # Overwrite the configurations method to add the RLS configurations
    class DatabaseShardsTest < ::ActiveSupport::TestCase
      attr_reader :active_record_base, :default_config

      setup do
        PgRls.reset_config!
        PgRls.class_name = :Org
        PgRls.table_name = :orgs
        PgRls.username = :tenant_user
        PgRls.password = :tenant_password

        ::ActiveRecord::Base.prepend(PgRls::ActiveRecord::DatabaseShards)
        @active_record_base = ::ActiveRecord::Base
        @default_config = {
          "adapter" => "postgresql",
          "encoding" => "unicode",
          "pool" => 5,
          "host" => "localhost",
          "port" => 5432,
          "username" => "postgres",
          "password" => "password",
          "database" => "dev_db"
        }
      end

      class SignleShardMode < self
        setup do
          @default_config.merge!("rls_mode" => "single")
        end

        test "rls mode is set to single" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_equal(new_rls_config["test"]["primary"]["rls_mode"], "single")
        end

        test "returns rls shard as default shard" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_not_nil(new_rls_config["test"]["primary"])
          assert_nil(new_rls_config["test"]["rls_primary"])
        end

        test "returns shard with assigned rls username" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_equal(new_rls_config["test"]["primary"]["username"], PgRls.username.to_s)
        end

        test "returns shard with assigned rls password" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_equal(new_rls_config["test"]["primary"]["password"], PgRls.password.to_s)
        end

        test "set database task to false" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_equal(new_rls_config["test"]["primary"]["database_tasks"], false)
        end

        class WithMultipleDatabases < self
          attr_reader :multiple_default_config

          setup do
            @multiple_default_config = { "test" => { "animals" => { **default_config },
                                                     "plants" => { **default_config.except("rls_mode") } } }
          end

          test "returns rls shard as default shard for each database" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_not_nil(new_rls_config["test"]["animals"])
            assert_not_nil(new_rls_config["test"]["plants"])
            assert_nil(new_rls_config["test"]["rls_animals"])
            assert_nil(new_rls_config["test"]["rls_plants"])
          end

          test "return shard with assigned rls username for each database with rls mode" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_equal(new_rls_config["test"]["animals"]["username"], PgRls.username.to_s)
            assert_equal(new_rls_config["test"]["plants"]["username"],
                         multiple_default_config["test"]["plants"]["username"])
          end

          test "return shard with assigned rls password for each database with rls mode" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_equal(new_rls_config["test"]["animals"]["password"], PgRls.password.to_s)
            assert_equal(new_rls_config["test"]["plants"]["password"],
                         multiple_default_config["test"]["plants"]["password"])
          end

          test "set database task to false for each database with rls mode" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_equal(new_rls_config["test"]["animals"]["database_tasks"], false)
            assert_nil(new_rls_config["test"]["plants"]["database_tasks"])
          end
        end
      end

      class NoneShardMode < self
        setup do
          @default_config.merge!("rls_mode" => "none")
        end

        test "rls mode is set to none" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_equal(new_rls_config["test"]["primary"]["rls_mode"], "none")
        end

        test "returns default shard" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_nil(new_rls_config["test"]["rls_primary"])
          assert_not_nil(new_rls_config["test"]["primary"])
        end

        test "returns shard with default/admin username" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_equal(new_rls_config["test"]["primary"]["username"], "postgres")
        end

        test "returns shard with default/admin password" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_equal(new_rls_config["test"]["primary"]["password"], "password")
        end

        test "does not set database task" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_nil(new_rls_config["test"]["primary"]["database_tasks"])
        end

        class WithMultipleDatabases < self
          attr_reader :multiple_default_config

          setup do
            @multiple_default_config = { "test" => { "animals" => { **default_config },
                                                     "plants" => { **default_config.except("rls_mode") } } }
          end

          test "returns rls shard as default shard for each database" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_not_nil(new_rls_config["test"]["animals"])
            assert_not_nil(new_rls_config["test"]["plants"])
            assert_nil(new_rls_config["test"]["rls_animals"])
            assert_nil(new_rls_config["test"]["rls_plants"])
          end

          test "return shard with default/admin username for each database with rls mode" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_equal(new_rls_config["test"]["animals"]["username"],
                         multiple_default_config["test"]["animals"]["username"])
            assert_equal(new_rls_config["test"]["plants"]["username"],
                         multiple_default_config["test"]["plants"]["username"])
          end

          test "return shard with default/admin password for each database with rls mode" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_equal(new_rls_config["test"]["animals"]["password"],
                         multiple_default_config["test"]["animals"]["password"])
            assert_equal(new_rls_config["test"]["plants"]["password"],
                         multiple_default_config["test"]["plants"]["password"])
          end

          test "does not set database task for each database with rls mode" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_nil(new_rls_config["test"]["animals"]["database_tasks"])
            assert_nil(new_rls_config["test"]["plants"]["database_tasks"])
          end
        end
      end

      class DualShardMode < self
        setup do
          @default_config.merge!("rls_mode" => "dual")
        end

        test "rls mode is set to dual" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_equal(new_rls_config["test"]["primary"]["rls_mode"], "dual")
        end

        test "returns primary and rls shard" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_not_nil(new_rls_config["test"]["primary"])
          assert_not_nil(new_rls_config["test"]["rls_primary"])
        end

        test "returns primary shard with default/admin username" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_equal(new_rls_config["test"]["primary"]["username"], "postgres")
        end

        test "returns primary shard with default/admin password" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_equal(new_rls_config["test"]["primary"]["password"], "password")
        end

        test "returns rls_primary shard with assigned rls username" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_equal(new_rls_config["test"]["rls_primary"]["username"], PgRls.username.to_s)
        end

        test "returns rls_primary shard with assigned rls password" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_equal(new_rls_config["test"]["rls_primary"]["password"], PgRls.password.to_s)
        end

        test "set database task to false for rls shard" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_equal(new_rls_config["test"]["rls_primary"]["database_tasks"], false)
        end

        test "does not set database task for primary shard" do
          new_rls_config = active_record_base.add_rls_configurations({ "test" => { **default_config } })
          assert_nil(new_rls_config["test"]["primary"]["database_tasks"])
        end

        class WithMultipleDatabases < self
          attr_reader :multiple_default_config

          setup do
            @multiple_default_config = { "test" => { "animals" => { **default_config },
                                                     "plants" => { **default_config.except("rls_mode") } } }
          end

          test "returns rls shard as default shard for each database" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_not_nil(new_rls_config["test"]["animals"])
            assert_not_nil(new_rls_config["test"]["plants"])
            assert_not_nil(new_rls_config["test"]["rls_animals"])
            assert_nil(new_rls_config["test"]["rls_plants"])
          end

          test "return shard with default/admin username for each database with rls mode" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_equal(new_rls_config["test"]["animals"]["username"],
                         multiple_default_config["test"]["animals"]["username"])
            assert_equal(new_rls_config["test"]["plants"]["username"],
                         multiple_default_config["test"]["plants"]["username"])
          end

          test "return shard with default/admin password for each database with rls mode" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_equal(new_rls_config["test"]["animals"]["password"],
                         multiple_default_config["test"]["animals"]["password"])
            assert_equal(new_rls_config["test"]["plants"]["password"],
                         multiple_default_config["test"]["plants"]["password"])
          end

          test "return rls shard with assigned rls username for each database with rls mode" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_equal(new_rls_config["test"]["rls_animals"]["username"], PgRls.username.to_s)
          end

          test "return rls shard with assigned rls password for each database with rls mode" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_equal(new_rls_config["test"]["rls_animals"]["password"], PgRls.password.to_s)
          end

          test "set database task to false for rls animal shard" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_equal(new_rls_config["test"]["rls_animals"]["database_tasks"], false)
          end

          test "does not set database task for any primary shard" do
            new_rls_config = active_record_base.add_rls_configurations(multiple_default_config)

            assert_nil(new_rls_config["test"]["animals"]["database_tasks"])
            assert_nil(new_rls_config["test"]["plants"]["database_tasks"])
          end
        end
      end

      class InvalidShardMode < self
        setup do
          @default_config.merge!("rls_mode" => "invalid")
        end

        test "raises an error" do
          assert_raises(ArgumentError) do
            active_record_base.add_rls_configurations({ "test" => { **default_config } })
          end
        end
      end
    end
  end
end
