# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in pg_rls.gemspec
gemspec

gem "rake", "~> 13.0"

group :development, :test do
  # Behaviour Driven Development Test [https://github.com/rspec/rspec-metagem]
  gem "rspec"

  # Code and Debug Report [https://github.com/simplecov-ruby/simplecov]
  gem "simplecov", require: false
  # Code Linting [https://github.com/rubocop/rubocop]
  gem "rubocop", require: false
  # Code Linting Performance optimization analysis [https://github.com/rubocop/rubocop-performance]
  gem "rubocop-performance", require: false
  # Code Linting RSpec-specific analysis [https://github.com/rubocop/rubocop-rspec]
  gem "rubocop-rspec", require: false
  # Code Linting Rake-specific analysis [https://github.com/rubocop/rubocop-rake]
  gem "rubocop-rake", require: false

  # Database Cleaner [https://github.com/DatabaseCleaner/database_cleaner]
  gem "database_cleaner"

  # Ruby Strong Typing [https://github.com/ruby/rbs]
  gem "rbs", require: false
  # Ruby Strong Typing Validations [https://github.com/soutaro/steep]
  gem "steep"
end
