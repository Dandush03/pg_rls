# frozen_string_literal: true

RSpec.describe PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::RlsUserStatements do
  let(:connection) { ActiveRecord::Base.connection }

  describe "#create_rls_role" do
    before do
      connection.create_rls_group
    end

    after do
      connection.drop_rls_role("test_app_user")
      connection.drop_rls_group
    end

    it "creates the role" do
      connection.create_rls_role("test_app_user", "password")

      expect(connection).to be_user_exists("test_app_user")
    end

    it "assigns the user to the group" do
      connection.create_rls_role("test_app_user", "password")

      expect(connection.send(:check_user_in_rls_group!, "test_app_user")).to be_truthy
    end

    it "creates the role rls_group" do
      connection.create_rls_role("test_app_user", "password")

      expect(connection).to be_user_exists("rls_group")
    end
  end

  describe "#user_exists?" do
    it "checks if the user exists" do
      connection.create_rls_user("test_app_user", "password")

      expect(connection).to be_user_exists("test_app_user")
    end
  end

  describe "#create_rls_group" do
    it "creates the group" do
      connection.create_rls_group

      expect(connection).to be_user_exists("rls_group")
    end
  end

  describe "#assign_user_to_group" do
    it "assigns the user to the group" do
      connection.create_rls_group
      connection.create_rls_user("test_app_user", "password")
      connection.assign_user_to_group("test_app_user")

      expect(connection.send(:check_user_in_rls_group!, "test_app_user")).to be_truthy
    end
  end

  describe "#create_rls_user" do
    it "creates the user" do
      connection.create_rls_user("test_app_user", "password")

      expect(connection).to be_user_exists("test_app_user")
    end
  end

  describe "#drop_rls_role" do
    before do
      connection.create_rls_role("test_app_user", "password")
    end

    it "removes the user from the group" do
      connection.drop_rls_role("test_app_user")

      expect do
        connection.send(:check_user_in_rls_group!,
                        "test_app_user")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserNotInPgRlsGroupError)
    end

    it "drops the user" do
      connection.drop_rls_role("test_app_user")

      expect(connection).not_to be_user_exists("test_app_user")
    end

    it "does not drops the group" do
      connection.drop_rls_role("test_app_user")

      expect(connection).to be_user_exists("rls_group")
    end
  end

  describe "#drop_rls_user" do
    before do
      connection.create_rls_user("test_app_user", "password")
    end

    it "drops the user" do
      connection.drop_rls_user("test_app_user")

      expect(connection).not_to be_user_exists("test_app_user")
    end
  end

  describe "#drop_rls_group" do
    before do
      connection.create_rls_group
    end

    it "drops the group" do
      connection.drop_rls_group

      expect(connection).not_to be_user_exists("rls_group")
    end
  end

  describe "#remove_user_from_group" do
    before do
      connection.create_rls_group
      connection.create_rls_user("test_app_user", "password")
      connection.assign_user_to_group("test_app_user")
    end

    after do
      connection.drop_rls_role("test_app_user")
      connection.drop_rls_group
    end

    it "removes the user from the group" do
      connection.remove_user_from_group("test_app_user")

      expect do
        connection.send(:check_user_in_rls_group!,
                        "test_app_user")
      end.to raise_error(PgRls::ActiveRecord::ConnectionAdapters::PostgreSQL::UserNotInPgRlsGroupError)
    end
  end
end
