# frozen_string_literal: true

RSpec.describe PgRls do
  it "has a version number" do
    expect(PgRls::VERSION).not_to be_nil
  end

  it "version is bigger or equal than 1.0.0" do
    expect(Gem::Version.new(PgRls::VERSION)).to be >= Gem::Version.new("1.0.0")
  end

  it "version is smaller than 1.1.0" do
    expect(Gem::Version.new(PgRls::VERSION)).to be < Gem::Version.new("1.1.0")
  end
end
