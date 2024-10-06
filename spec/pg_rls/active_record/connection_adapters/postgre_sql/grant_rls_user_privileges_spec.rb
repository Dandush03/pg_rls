# frozen_string_literal: true

RSpec.describe PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::GrantRlsUserPrivileges do
  let(:connection) { ActiveRecord::Base.connection }

  before do
    connection.create_rls_group
    connection.create_rls_role("test_app_user", "test_app_password")
  end

  after do
    connection.drop_rls_user("test_app_user")
    connection.revoke_rls_user_privileges("public")
    connection.drop_rls_group
    connection.drop_table(:test_table, if_exists: true)
  end

  describe "#grant_rls_user_privileges" do
    it "grants user privileges" do
      expect { connection.grant_rls_user_privileges("public") }.not_to raise_error
    end

    it "grant usage on schema" do
      connection.grant_rls_user_privileges("public")
      expect(connection.send(:check_schema_usage_privilege!, "rls_group", "public")).to be_truthy
    end

    it "grant default sequence privileges" do
      connection.grant_rls_user_privileges("public")
      expect(connection.send(:check_default_sequence_privileges!, "rls_group", "public")).to be_truthy
    end

    it "grant default table privileges" do
      connection.grant_rls_user_privileges("public")
      expect(connection.send(:check_default_table_privileges!, "rls_group", "public")).to be_truthy
    end

    it "grant existing table privileges" do
      connection.create_table(:test_table)
      connection.grant_rls_user_privileges("public")
      expect(connection.send(:check_table_privileges!, "rls_group", "public", "test_table")).to be_truthy
    end

    it "grant existing sequence privileges" do
      connection.create_table(:test_table)
      connection.grant_rls_user_privileges("public")
      expect(connection.send(:check_sequence_privileges!, "rls_group", "public", "test_table_id_seq")).to be_truthy
    end
  end

  describe "#revoke_rls_user_privileges" do
    before do
      connection.create_table(:test_table)
      connection.grant_rls_user_privileges("public")
    end

    it "revokes user privileges" do
      expect { connection.revoke_rls_user_privileges("public") }.not_to raise_error
    end

    it "revoke usage on schema" do
      connection.revoke_rls_user_privileges("public")
      expect do
        connection.send(:check_schema_usage_privilege!, "rls_group",
                        "public")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserMissingSchemaUsagePrivilegeError)
    end

    it "revoke default sequence privileges" do
      connection.revoke_rls_user_privileges("public")
      expect do
        connection.send(:check_default_sequence_privileges!, "rls_group",
                        "public")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserMissingSequencePrivilegesError)
    end

    it "revoke default table privileges" do
      connection.revoke_rls_user_privileges("public")
      expect do
        connection.send(:check_default_table_privileges!, "rls_group",
                        "public")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserMissingTablePrivilegesError)
    end

    it "revoke existing table privileges" do
      connection.revoke_rls_user_privileges("public")
      expect do
        connection.send(:check_table_privileges!, "rls_group", "public",
                        "test_table")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserMissingTablePrivilegesError)
    end

    it "revoke existing sequence privileges" do
      connection.revoke_rls_user_privileges("public")
      expect do
        connection.send(:check_sequence_privileges!, "rls_group", "public",
                        "test_table_id_seq")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserMissingSequencePrivilegesError)
    end
  end
end
