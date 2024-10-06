# frozen_string_literal: true

RSpec.describe PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::RlsTriggers do
  before do
    ActiveRecord::Base.connection.create_rls_functions
    ActiveRecord::Base.connection.create_table("table_name") { |t| t.integer :tenant_id }
  end

  after do
    ActiveRecord::Base.connection.drop_rls_functions
    ActiveRecord::Base.connection.drop_table("table_name")
  end

  describe "#create_tenant_table_triggers" do
    it "creates the rls_exception trigger" do
      ActiveRecord::Base.connection.create_tenant_table_triggers("table_name")

      expect(ActiveRecord::Base.connection).to be_trigger_exists("table_name",
                                                                 "table_name_rls_exception_trigger")
    end
  end

  describe "#append_rls_table_triggers" do
    it "creates the tenant_id_setter trigger" do
      ActiveRecord::Base.connection.append_rls_table_triggers("table_name")

      expect(ActiveRecord::Base.connection).to be_trigger_exists("table_name",
                                                                 "table_name_tenant_id_setter_trigger")
    end

    it "creates the tenant_id_update_blocker trigger" do
      ActiveRecord::Base.connection.append_rls_table_triggers("table_name")

      expect(ActiveRecord::Base.connection).to be_trigger_exists("table_name",
                                                                 "table_name_tenant_id_update_blocker_trigger")
    end
  end

  describe "#drop_tenant_table_triggers" do
    it "drops the rls_exception trigger" do
      ActiveRecord::Base.connection.create_tenant_table_triggers("table_name")
      ActiveRecord::Base.connection.drop_tenant_table_triggers("table_name")

      expect(ActiveRecord::Base.connection).not_to be_trigger_exists("table_name",
                                                                     "table_name_rls_exception_trigger")
    end
  end

  describe "#drop_rls_table_triggers" do
    it "drops the tenant_id_setter trigger" do
      ActiveRecord::Base.connection.append_rls_table_triggers("table_name")
      ActiveRecord::Base.connection.drop_rls_table_triggers("table_name")

      expect(ActiveRecord::Base.connection).not_to be_trigger_exists("table_name",
                                                                     "table_name_tenant_id_setter_trigger")
    end

    it "drops the tenant_id_update_blocker trigger" do
      ActiveRecord::Base.connection.append_rls_table_triggers("table_name")
      ActiveRecord::Base.connection.drop_rls_table_triggers("table_name")

      expect(ActiveRecord::Base.connection).not_to be_trigger_exists("table_name",
                                                                     "table_name_tenant_id_update_blocker_trigger")
    end
  end
end
