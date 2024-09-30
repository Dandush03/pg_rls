# frozen_string_literal: true

RSpec.describe PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::RlsFunctions do
  describe "#function_exists?" do
    it "returns false when function does not exists" do
      ActiveRecord::Base.connection.drop_function("function_name")

      expect(ActiveRecord::Base.connection).not_to be_function_exists("function_name")
    end

    it "returns true when function exists" do
      ActiveRecord::Base.connection.create_function("function_name", "BEGIN RETURN NULL; END;")

      expect(ActiveRecord::Base.connection).to be_function_exists("function_name")
    end
  end

  describe "#create_function" do
    it "creates a function" do
      ActiveRecord::Base.connection.create_function("function_name", "BEGIN RETURN NULL; END;")

      expect(ActiveRecord::Base.connection).to be_function_exists("function_name")
    end

    context "when function already exists" do
      it "replaces the function" do
        ActiveRecord::Base.connection.create_function("function_name", "BEGIN RETURN NULL; END;")
        ActiveRecord::Base.connection.create_function("function_name", "BEGIN RETURN 1; END;")

        expect(ActiveRecord::Base.connection).to be_function_exists("function_name")
      end
    end
  end

  describe "#drop_function" do
    it "drops a function" do
      ActiveRecord::Base.connection.create_function("function_name", "BEGIN RETURN NULL; END;")
      ActiveRecord::Base.connection.drop_function("function_name")

      expect(ActiveRecord::Base.connection).not_to be_function_exists("function_name")
    end

    context "when function does not exists" do
      it "does nothing" do
        ActiveRecord::Base.connection.drop_function("function_name")

        expect(ActiveRecord::Base.connection).not_to be_function_exists("function_name")
      end
    end
  end
end
