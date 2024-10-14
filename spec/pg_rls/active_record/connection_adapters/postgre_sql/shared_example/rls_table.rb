# frozen_string_literal: true

RSpec.shared_examples "behaves like rls table" do |table_name|
  it "ensure that a rls tenant table exists" do
    expect(connection).to be_table_exists(table_name)
  end

  it "ensure users and users privileges exists" do
    expect(connection.check_rls_user_privileges!("app_user", "public")).to be_truthy
  end

  it "ensure tenant_id_setter function exists" do
    expect(connection).to be_function_exists("tenant_id_setter")
  end

  it "ensure rls_exception function exists" do
    expect(connection).to be_function_exists("rls_exception")
  end

  it "ensure tenant_id_update_blocker function exists" do
    expect(connection).to be_function_exists("tenant_id_update_blocker")
  end

  it "ensure tenant_id column exists" do
    expect(connection.columns(table_name).map(&:name)).to include("tenant_id")
  end

  it "ensure rls table has enabled rls" do
    expect(connection.check_table_rls_enabled!("test_table")).to be_truthy
  end

  it "ensure tenant_id_setter trigger is appended to table" do
    expect(connection).to be_trigger_exists(table_name, "tenant_id_setter")
  end

  it "ensure tenant_id_update_blocker trigger is appended to table" do
    expect(connection).to be_trigger_exists(table_name, "tenant_id_update_blocker")
  end

  context "when rls is set" do
    let(:tenant_uuid) { SecureRandom.uuid }

    before do
      connection.execute("SET rls.tenant_id = '#{tenant_uuid}'")
    end

    after do
      connection.execute("RESET rls.tenant_id")
    end

    it "ensure that the rls tenant_id is set in row after insert" do
      connection.execute("INSERT INTO test_table (name) VALUES ('test')")

      record_uuid = connection.execute("SELECT tenant_id FROM test_table WHERE name = 'test'").first["tenant_id"]
      expect(record_uuid).to eq(tenant_uuid)
    end

    it "raises an InvalidStatement error if tenant_id is manualy updated" do
      uuid = SecureRandom.uuid
      connection.execute("INSERT INTO test_table (name) VALUES ('test')")

      expect do
        connection.execute("UPDATE test_table SET tenant_id = '#{uuid}' WHERE name = 'test'")
      end.to raise_error(ActiveRecord::StatementInvalid).with_message(/tenant_id_update_blocker/)
    end

    it "find all records" do
      connection.execute("INSERT INTO test_table (name) VALUES ('test')")
      connection.execute("SET rls.tenant_id = '#{SecureRandom.uuid}'")
      connection.execute("INSERT INTO test_table (name) VALUES ('test')")
      connection.execute("RESET rls.tenant_id")
      expect(connection.execute("SELECT * FROM test_table").to_a.size).to eq(2)
    end
  end

  context "when rls is not set" do
    let(:insert_record1!) do
      connection.execute("SET rls.tenant_id = '#{SecureRandom.uuid}'")
      connection.execute("INSERT INTO test_table (name) VALUES ('test')")
      connection.execute("RESET rls.tenant_id")
    end

    let(:insert_record2!) do
      connection.execute("SET rls.tenant_id = '#{SecureRandom.uuid}'")
      connection.execute("INSERT INTO test_table (name) VALUES ('test')")
      connection.execute("RESET rls.tenant_id")
    end

    it "raises an error if the tenant_id is not set" do
      expect do
        connection.execute("INSERT INTO test_table (name) VALUES ('test')")
      end.to raise_error(ActiveRecord::StatementInvalid).with_message(/tenant_id_setter/)
    end

    it "allows admin to update the record regardless of if the tenant_id is set" do
      insert_record1!
      expect do
        connection.execute("UPDATE test_table SET name = 'test2' WHERE name = 'test'")
      end.not_to raise_error
    end

    it "find all records" do
      insert_record1!
      insert_record2!
      expect(connection.execute("SELECT * FROM test_table").to_a.size).to eq(2)
    end
  end
end

RSpec.shared_examples "absence of rls table" do |table_name|
  it "ensure tenant_id column does not exists if table exists" do
    if connection.table_exists?(table_name)
      expect(connection.columns(table_name).map(&:name)).not_to include("tenant_id")
    end
  end

  it "ensure rls table does not has enabled rls" do
    expect do
      connection.check_table_rls_enabled!("test_table")
    end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::TableRlsNotEnabledError)
  end

  it "ensure tenant_id_setter trigger is not appended to table" do
    expect(connection).not_to be_trigger_exists(table_name, "tenant_id_setter")
  end

  it "ensure tenant_id_update_blocker trigger not is appended to table" do
    expect(connection).not_to be_trigger_exists(table_name, "tenant_id_update_blocker")
  end

  context "when rls is set" do
    let(:tenant_uuid) { SecureRandom.uuid }

    before do
      connection.execute("SET rls.tenant_id = '#{tenant_uuid}'")
    end

    after do
      connection.execute("RESET rls.tenant_id")
    end

    it "ensure that the rls tenant_id does not raise any errors" do
      if connection.table_exists?(table_name)
        expect do
          connection.execute("INSERT INTO test_table (name) VALUES ('test')")
        end.not_to raise_error
      end
    end

    it "find all records" do # rubocop:disable RSpec/ExampleLength
      if connection.table_exists?(table_name)
        connection.execute("INSERT INTO test_table (name) VALUES ('test')")
        connection.execute("SET rls.tenant_id = '#{SecureRandom.uuid}'")
        connection.execute("INSERT INTO test_table (name) VALUES ('test')")
        connection.execute("RESET rls.tenant_id")
        expect(connection.execute("SELECT * FROM test_table").to_a.size).to eq(2)
      end
    end
  end

  context "when rls is not set" do
    let(:insert_record1!) do
      connection.execute("SET rls.tenant_id = '#{SecureRandom.uuid}'")
      connection.execute("INSERT INTO test_table (name) VALUES ('test')")
      connection.execute("RESET rls.tenant_id")
    end

    let(:insert_record2!) do
      connection.execute("SET rls.tenant_id = '#{SecureRandom.uuid}'")
      connection.execute("INSERT INTO test_table (name) VALUES ('test')")
      connection.execute("RESET rls.tenant_id")
    end

    it "does not raises an error if the tenant_id is not set" do
      if connection.table_exists?(table_name)
        expect do
          connection.execute("INSERT INTO test_table (name) VALUES ('test')")
        end.not_to raise_error
      end
    end

    it "find all records" do
      if connection.table_exists?(table_name)
        insert_record1!
        insert_record2!
        expect(connection.execute("SELECT * FROM test_table").to_a.size).to eq(2)
      end
    end
  end
end
