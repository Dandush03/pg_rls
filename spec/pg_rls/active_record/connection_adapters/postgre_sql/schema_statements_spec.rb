# frozen_string_literal: true

require_relative "shared_example/tenant_table"
require_relative "shared_example/rls_table"

RSpec.describe PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements do
  subject(:connection) { ActiveRecord::Base.connection }

  describe ".create_rls_tenant_table" do
    before do
      connection.create_rls_tenant_table(:test_table) { |t| t.string :name }
    end

    after do
      connection.drop_rls_tenant_table(:test_table, if_exists: true)
    end

    include_examples "behaves like rls tenant table", :test_table
  end

  describe ".drop_rls_tenant_table" do
    before do
      connection.create_rls_tenant_table(:test_table) { |t| t.string :name }
      connection.drop_rls_tenant_table(:test_table)
    end

    it "ensure that a rls tenant table does not exist" do
      expect(connection).not_to be_table_exists(:test_table)
    end

    include_examples "absence of rls tenant table", :test_table
  end

  describe ".invert_create_rls_tenant_table" do
    before do
      connection.create_rls_tenant_table(:test_table) { |t| t.string :name }
      connection.invert_create_rls_tenant_table(:test_table)
    end

    it "ensure that a rls tenant table does not exist" do
      expect(connection).not_to be_table_exists(:test_table)
    end

    include_examples "absence of rls tenant table", :test_table
  end

  describe ".convert_to_rls_tenant_table" do
    before do
      connection.create_table(:test_table) { |t| t.string :name }
      connection.convert_to_rls_tenant_table(:test_table)
    end

    after do
      connection.drop_table(:test_table, if_exists: true)
    end

    include_examples "behaves like rls tenant table", :test_table
  end

  describe ".revert_from_rls_tenant_table" do
    before do
      connection.create_table(:test_table) { |t| t.string :name }
      connection.convert_to_rls_tenant_table(:test_table)

      connection.revert_from_rls_tenant_table(:test_table)
    end

    after do
      connection.drop_table(:test_table)
    end

    it "ensure that a rls tenant table persist" do
      expect(connection).to be_table_exists(:test_table)
    end

    it "does not have a tenant_id column" do
      expect(connection.columns(:test_table).map(&:name)).not_to include("tenant_id")
    end

    it "does not have a tenant_id index" do
      expect(connection.indexes(:test_table).map(&:name)).not_to include("index_test_table_on_tenant_id")
    end

    include_examples "absence of rls tenant table", :test_table
  end

  describe ".invert_convert_to_rls_tenant_table" do
    before do
      connection.create_table(:test_table) { |t| t.string :name }
      connection.convert_to_rls_tenant_table(:test_table)

      connection.invert_convert_to_rls_tenant_table(:test_table)
    end

    after do
      connection.drop_table(:test_table)
    end

    it "ensure that a rls tenant table persist" do
      expect(connection).to be_table_exists(:test_table)
    end

    it "does not have a tenant_id column" do
      expect(connection.columns(:test_table).map(&:name)).not_to include("tenant_id")
    end

    it "does not have a tenant_id index" do
      expect(connection.indexes(:test_table).map(&:name)).not_to include("index_test_table_on_tenant_id")
    end

    include_examples "absence of rls tenant table", :test_table
  end

  describe ".create_rls_table" do
    before do
      connection.create_rls_tenant_table(:tenant_table) { |t| t.string :name }
      connection.create_rls_table(:test_table) { |t| t.string :name }
    end

    after do
      connection.drop_rls_table(:test_table, if_exists: true)
      connection.drop_rls_tenant_table(:tenant_table, if_exists: true)
    end

    include_examples "behaves like rls table", :test_table
  end

  describe ".drop_rls_table" do
    before do
      connection.create_rls_tenant_table(:tenant_table) { |t| t.string :name }
      connection.create_rls_table(:test_table) { |t| t.string :name }
      connection.drop_rls_table(:test_table)
    end

    after do
      connection.drop_rls_table(:test_table, if_exists: true)
      connection.drop_rls_tenant_table(:tenant_table, if_exists: true)
    end

    include_examples "absence of rls table", :test_table
  end

  describe ".invert_create_rls_table" do
    before do
      connection.create_rls_tenant_table(:tenant_table) { |t| t.string :name }
      connection.create_rls_table(:test_table) { |t| t.string :name }
      connection.invert_create_rls_table(:test_table)
    end

    after do
      connection.drop_rls_table(:test_table, if_exists: true)
      connection.drop_rls_tenant_table(:tenant_table, if_exists: true)
    end

    include_examples "absence of rls table", :test_table
  end

  describe ".convert_to_rls_table" do
    before do
      connection.create_rls_tenant_table(:tenant_table) { |t| t.string :name }
      connection.create_table(:test_table) { |t| t.string :name }
      connection.convert_to_rls_table(:test_table)
    end

    after do
      connection.drop_table(:test_table, if_exists: true)
      connection.drop_rls_tenant_table(:tenant_table, if_exists: true)
    end

    include_examples "behaves like rls table", :test_table
  end

  describe ".revert_from_rls_table" do
    before do
      connection.create_rls_tenant_table(:tenant_table) { |t| t.string :name }
      connection.create_table(:test_table) { |t| t.string :name }
      connection.convert_to_rls_table(:test_table)

      connection.revert_from_rls_table(:test_table)
    end

    after do
      connection.drop_table(:test_table, if_exists: true)
      connection.drop_rls_tenant_table(:tenant_table, if_exists: true)
    end

    it "ensure that a rls table persist" do
      expect(connection).to be_table_exists(:test_table)
    end

    include_examples "absence of rls table", :test_table
  end
end
