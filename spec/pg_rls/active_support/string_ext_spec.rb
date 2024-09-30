# frozen_string_literal: true

RSpec.describe PgRls::ActiveSupport::StringExt do
  describe "#sanitize_sql" do
    it "does not modify a string without extra spaces" do
      expect("SELECT * FROM table".sanitize_sql).to eq("SELECT * FROM table")
    end

    it "removes trailing spaces" do
      expect("SELECT * FROM table ".sanitize_sql).to eq("SELECT * FROM table")
    end

    it "removes leading spaces" do
      expect(" SELECT * FROM table".sanitize_sql).to eq("SELECT * FROM table")
    end

    it "removes both leading and trailing spaces" do
      expect(" SELECT * FROM table ".sanitize_sql).to eq("SELECT * FROM table")
    end

    it "removes extra spaces between words" do
      expect("SELECT  *  FROM  table".sanitize_sql).to eq("SELECT * FROM table")
    end

    it "removes tabs" do
      expect("SELECT\t*\tFROM\ttable".sanitize_sql).to eq("SELECT * FROM table")
    end

    it "removes newlines" do
      expect("SELECT\n*\nFROM\ntable".sanitize_sql).to eq("SELECT * FROM table")
    end

    it "removes a combination of newlines, tabs, and spaces" do
      expect(" SELECT\t*\nFROM  \ttable ".sanitize_sql).to eq("SELECT * FROM table")
    end
  end
end
