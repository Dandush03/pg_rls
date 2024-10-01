# frozen_string_literal: true

RSpec.describe PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::RlsFunctions do
  describe "#function_exists?" do
    it "returns false when function does not exists" do
      ActiveRecord::Base.connection.send(:drop_function, "function_name")

      expect(ActiveRecord::Base.connection).not_to be_function_exists("function_name")
    end

    it "returns true when function exists" do
      ActiveRecord::Base.connection.send(:create_function, "function_name", "BEGIN RETURN NULL; END;")

      expect(ActiveRecord::Base.connection).to be_function_exists("function_name")
    end
  end

  describe ".create_function" do
    it "creates a function" do
      ActiveRecord::Base.connection.send(:create_function, "function_name", "BEGIN RETURN NULL; END;")

      expect(ActiveRecord::Base.connection).to be_function_exists("function_name")
    end

    context "when function already exists" do
      it "replaces the function" do
        ActiveRecord::Base.connection.send(:create_function, "function_name", "BEGIN RETURN NULL; END;")
        ActiveRecord::Base.connection.send(:create_function, "function_name", "BEGIN RETURN 1; END;")

        expect(ActiveRecord::Base.connection).to be_function_exists("function_name")
      end
    end
  end

  describe ".drop_function" do
    it "drops a function" do
      ActiveRecord::Base.connection.send(:create_function, "function_name", "BEGIN RETURN NULL; END;")
      ActiveRecord::Base.connection.send(:drop_function, "function_name")

      expect(ActiveRecord::Base.connection).not_to be_function_exists("function_name")
    end

    context "when function does not exists" do
      it "does nothing" do
        ActiveRecord::Base.connection.send(:drop_function, "function_name")

        expect(ActiveRecord::Base.connection).not_to be_function_exists("function_name")
      end
    end
  end

  describe "#create_rls_functions" do
    it "creates the tenant_id_setter function" do
      ActiveRecord::Base.connection.create_rls_functions

      expect(ActiveRecord::Base.connection).to be_function_exists("tenant_id_setter")
    end

    it "creates the tenant_id_update_blocker function" do
      ActiveRecord::Base.connection.create_rls_functions

      expect(ActiveRecord::Base.connection).to be_function_exists("tenant_id_update_blocker")
    end

    it "creates the rls_blocking_function function" do
      ActiveRecord::Base.connection.create_rls_functions

      expect(ActiveRecord::Base.connection).to be_function_exists("rls_blocking_function")
    end
  end

  describe "#drop_rls_functions" do
    it "drops the tenant_id_setter function" do
      ActiveRecord::Base.connection.create_rls_functions
      ActiveRecord::Base.connection.drop_rls_functions

      expect(ActiveRecord::Base.connection).not_to be_function_exists("tenant_id_setter")
    end

    it "drops the tenant_id_update_blocker function" do
      ActiveRecord::Base.connection.create_rls_functions
      ActiveRecord::Base.connection.drop_rls_functions

      expect(ActiveRecord::Base.connection).not_to be_function_exists("tenant_id_update_blocker")
    end

    it "drops the rls_blocking_function function" do
      ActiveRecord::Base.connection.create_rls_functions
      ActiveRecord::Base.connection.drop_rls_functions

      expect(ActiveRecord::Base.connection).not_to be_function_exists("rls_blocking_function")
    end
  end
end
