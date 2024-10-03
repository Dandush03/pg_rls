# frozen_string_literal: true

RSpec.describe PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::SqlHelperMethod do
  describe "#execute_sql!" do
    let(:connection) { ActiveRecord::Base.connection }

    before do
      ActiveRecord::ConnectionAdapters::AbstractAdapter.include(described_class)
      allow(connection).to receive(:execute).and_return(true)
      connection.send(:execute_sql!, "SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'test_app_user';")
    end

    it "executes the SQL statement" do
      expect(connection).to have_received(:execute)
        .with("SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'test_app_user';")
    end

    it "executes the statement once" do
      expect(connection).to have_received(:execute).once
    end
  end
end
