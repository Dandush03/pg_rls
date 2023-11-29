# frozen_string_literal: true

RSpec.describe PgRls do
  it 'has a version number' do
    expect(PgRls::VERSION).not_to be_nil
  end

  it 'does something useful' do
    expect(require_relative('../lib/pg_rls/version')).to be(false)
  end
end
