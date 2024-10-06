# frozen_string_literal: true

RSpec.describe PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::CheckRlsUserPrivileges do
  let(:connection) { ActiveRecord::Base.connection }

  before do
    connection.create_rls_group
    connection.create_rls_role("test_app_user", "test_app_password")
  end

  after do
    connection.revoke_rls_user_privileges("public") if connection.user_exists?("test_app_user")
    connection.drop_rls_role("test_app_user")
    connection.drop_rls_group
    connection.drop_table(:test_table, if_exists: true)
  end

  describe ".check_rls_user_privileges!" do
    it "checks the user privileges" do
      connection.grant_rls_user_privileges("public")

      expect(connection.send(:check_rls_user_privileges!, "test_app_user", "public")).to be_truthy
    end

    it "raises an PgRls::Error if the user does not exist" do # rubocop:disable RSpec/MultipleExpectations
      connection.revoke_rls_user_privileges("public")

      expect do
        connection.send(:check_rls_user_privileges!, "test_app_user", "public")
      end.to(raise_error { |error| expect(error).to be_a(PgRls::Error) })
    end
  end

  describe ".check_user_exists!" do
    it "checks if the user exists" do
      expect(connection.send(:check_user_exists!, "test_app_user")).to be_truthy
    end

    it "raises an error if the user does not exist" do
      connection.drop_rls_user("test_app_user")

      expect do
        connection.send(:check_user_exists!, "test_app_user")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserDoesNotExistError)
    end
  end

  describe ".check_user_in_rls_group!" do
    it "checks if the user is in the rls_group" do
      expect(connection.send(:check_user_in_rls_group!, "test_app_user")).to be_truthy
    end

    it "raises an error if the user is not in the rls_group" do
      connection.remove_user_from_group("test_app_user")
      expect do
        connection.send(:check_user_in_rls_group!, "test_app_user")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserNotInPgRlsGroupError)
    end
  end

  describe ".check_schema_usage_privilege!" do
    it "checks the user schema usage privileges" do
      connection.grant_rls_user_privileges("public")
      expect(connection.send(:check_schema_usage_privilege!, "rls_group", "public")).to be_truthy
    end

    it "raises an error if the user does not have the schema usage privileges" do
      expect do
        connection.send(:check_schema_usage_privilege!, "rls_group", "public")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserMissingSchemaUsagePrivilegeError)
    end
  end

  describe ".check_default_table_privileges!" do
    it "checks the user default table privileges" do
      connection.grant_rls_user_privileges("public")
      expect(connection.send(:check_default_table_privileges!, "rls_group", "public")).to be_truthy
    end

    it "raises an error if the user does not have the default table privileges" do
      expect do
        connection.send(:check_default_table_privileges!, "rls_group", "public")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserMissingTablePrivilegesError)
    end
  end

  describe ".check_table_privileges!" do
    it "checks the user table privileges" do
      connection.grant_rls_user_privileges("public")
      connection.create_table(:test_table)
      expect(connection.send(:check_table_privileges!, "rls_group", "public", "test_table")).to be_truthy
    end

    it "raises an error if the user does not have the table privileges" do
      expect do
        connection.send(:check_table_privileges!, "rls_group", "public", "test_table")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserMissingTablePrivilegesError)
    end
  end

  describe ".check_default_sequence_privileges!" do
    it "checks the user default sequence privileges" do
      connection.grant_rls_user_privileges("public")
      expect(connection.send(:check_default_sequence_privileges!, "rls_group", "public")).to be_truthy
    end

    it "raises an error if the user does not have the default sequence privileges" do
      expect do
        connection.send(:check_default_sequence_privileges!, "rls_group", "public")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserMissingSequencePrivilegesError)
    end
  end

  describe ".check_sequence_privileges!" do
    it "checks the user sequence privileges" do
      connection.grant_rls_user_privileges("public")
      connection.create_table(:test_table)
      expect(connection.send(:check_sequence_privileges!, "rls_group", "public", "test_table_id_seq")).to be_truthy
    end

    it "raises an error if the user does not have the sequence privileges" do
      expect do
        connection.send(:check_sequence_privileges!, "rls_group", "public", "test_table_id_seq")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserMissingSequencePrivilegesError)
    end
  end

  describe ".check_table_rls_enabled!" do
    before do
      connection.create_table(:test_table) { |t| t.uuid :tenant_id }
    end

    after do
      connection.disable_table_rls("test_table", "public")
      connection.drop_table(:test_table, if_exists: true)
    end

    it "checks if the table rls is enabled" do
      connection.enable_table_rls("test_table", "public")
      expect(connection.check_table_rls_enabled!("test_table")).to be_truthy
    end

    it "raises an error if the table rls is not enabled" do
      expect do
        connection.check_table_rls_enabled!("test_table")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::TableRlsNotEnabledError)
    end
  end

  describe ".check_table_user_policy_exists!" do
    before do
      connection.create_table(:test_table) { |t| t.uuid :tenant_id }
    end

    after do
      connection.disable_table_rls("test_table", "public")
      connection.drop_table(:test_table, if_exists: true)
    end

    it "checks if the table user policy exists" do
      connection.enable_table_rls("test_table", "public")
      expect(connection.check_table_user_policy_exists!("test_table", "public")).to be_truthy
    end

    it "raises an error if the table user policy does not exist" do
      expect do
        connection.check_table_user_policy_exists!("test_table", "test_app_user")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::TableUserPolicyDoesNotExistError)
    end
  end
end
