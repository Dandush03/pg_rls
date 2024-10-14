# frozen_string_literal: true

RSpec.shared_examples "behaves like rls tenant table" do |table_name|
  it "ensure that a rls tenant table exists" do
    expect(connection).to be_table_exists(table_name)
  end

  it "creates rls_group and user with default privileges" do
    expect(connection.check_rls_user_privileges!("app_user", "public")).to be_truthy
  end

  it "creates tenant_id_setter function" do
    expect(connection).to be_function_exists("tenant_id_setter")
  end

  it "creates rls_exception function" do
    expect(connection).to be_function_exists("rls_exception")
  end

  it "creates tenant_id_update_blocker function" do
    expect(connection).to be_function_exists("tenant_id_update_blocker")
  end

  it "appends rls column tenant_id" do
    expect(connection.columns(table_name).map(&:name)).to include("tenant_id")
  end

  it "ensures tenant_id column is indexed" do
    expect(connection.indexes(table_name).map(&:name)).to include("index_#{table_name}_on_tenant_id")
  end

  it "appends tenant table triggers (tenant_id_setter)" do
    expect(connection).to be_trigger_exists(table_name, "rls_exception")
  end

  it "raises an InvalidStatement error if the row tenant_id is edited" do
    connection.execute("INSERT INTO #{table_name} (name) VALUES ('test')")

    expect do
      connection.execute("UPDATE #{table_name} SET tenant_id = 'test' WHERE name = 'test'")
    end.to raise_error(ActiveRecord::StatementInvalid)
  end
end

RSpec.shared_examples "absence of rls tenant table" do |table_name|
  it "rls_group and user with default privileges does not exists" do # rubocop:disable RSpec/MultipleExpectations
    expect do
      connection.check_rls_user_privileges!("app_user", "public")
    end.to(raise_error { |error| expect(error).to be_a(PgRls::Error) })
  end

  it "tenant_id_setter function does not exists" do
    expect(connection).not_to be_function_exists("tenant_id_setter")
  end

  it "rls_exception function does not exists" do
    expect(connection).not_to be_function_exists("rls_exception")
  end

  it "tenant_id_update_blocker function does not exists" do
    expect(connection).not_to be_function_exists("tenant_id_update_blocker")
  end

  it "tenant table triggers (tenant_id_setter) does not exists" do
    expect(connection).not_to be_trigger_exists(table_name, "rls_exception")
  end
end
